#!/usr/bin/env python3
"""Small dependency-free exporter for old receiver hardware.

Compatible with Python 3.6+ and intentionally limited to /proc and os APIs.
The renderer should run renderer-success after a successful framebuffer draw.
"""
import argparse
import json
import os
import shutil
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


def read_load():
    try:
        with open('/proc/loadavg') as stream:
            return stream.read().split()[0]
    except (IOError, IndexError):
        return '0'


def read_mem():
    values = {}
    try:
        with open('/proc/meminfo') as stream:
            for line in stream:
                key, value = line.split(':', 1)
                values[key] = int(value.split()[0]) * 1024
    except (IOError, ValueError):
        pass
    return values


class DiskUsageCache(object):
    def __init__(self, paths, interval_minutes):
        self.paths = paths
        self.interval = max(0.0, interval_minutes * 60.0)
        self.lock = threading.Lock()
        self.expires = 0
        self.values = []

    def read(self):
        now = time.time()
        with self.lock:
            if now < self.expires:
                return self.values
            values = []
            for path in self.paths:
                try:
                    usage = shutil.disk_usage(path)
                    values.append((path, usage.total, usage.used, usage.free, 1))
                except OSError:
                    values.append((path, 0, 0, 0, 0))
            self.values = values
            self.expires = now + self.interval
            return values


def read_os_info(path):
    """Read key/value, JSON object, or plain-line data from an os-info file."""
    try:
        with open(path) as stream:
            content = stream.read(16384).strip()
    except (IOError, OSError):
        return []
    if not content:
        return []
    try:
        parsed = json.loads(content)
        if isinstance(parsed, dict):
            return [(str(key), str(value)) for key, value in parsed.items()]
    except (ValueError, TypeError):
        pass
    values = []
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, value = line.split('=', 1)
            values.append((key.strip(), value.strip().strip('"')))
        else:
            values.append(('value', line))
    return values


def label(value):
    return str(value).replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')


def metrics(heartbeat, stale_after, disk_cache, os_info_path):
    now = time.time()
    try:
        last = os.path.getmtime(heartbeat)
        success = 1 if now - last <= stale_after else 0
    except OSError:
        last = 0
        success = 0
    memory = read_mem()
    lines = [
        '# HELP receiver_renderer_success Whether the renderer succeeded recently.',
        '# TYPE receiver_renderer_success gauge',
        'receiver_renderer_success %d' % success,
        '# HELP receiver_renderer_last_success_timestamp_seconds Unix time of the last successful render.',
        '# TYPE receiver_renderer_last_success_timestamp_seconds gauge',
        'receiver_renderer_last_success_timestamp_seconds %.3f' % last,
        '# HELP receiver_load1 Receiver one-minute load average.',
        '# TYPE receiver_load1 gauge',
        'receiver_load1 %s' % read_load(),
    ]
    if 'MemTotal' in memory:
        lines += [
            '# TYPE receiver_memory_bytes gauge',
            'receiver_memory_bytes{state="total"} %d' % memory['MemTotal'],
            'receiver_memory_bytes{state="available"} %d' % memory.get('MemAvailable', 0),
        ]
    lines += [
        '# HELP receiver_disk_bytes Filesystem capacity and usage.',
        '# TYPE receiver_disk_bytes gauge',
        '# HELP receiver_disk_usage_read_success Whether the filesystem read succeeded.',
        '# TYPE receiver_disk_usage_read_success gauge',
    ]
    for path, total, used, free, available in disk_cache.read():
        path_label = label(path)
        lines += [
            'receiver_disk_bytes{path="%s",state="total"} %d' % (path_label, total),
            'receiver_disk_bytes{path="%s",state="used"} %d' % (path_label, used),
            'receiver_disk_bytes{path="%s",state="free"} %d' % (path_label, free),
            'receiver_disk_usage_read_success{path="%s"} %d' % (path_label, available),
        ]
    lines += [
        '# HELP receiver_os_info Information read from the os-info file.',
        '# TYPE receiver_os_info gauge',
    ]
    for key, value in read_os_info(os_info_path):
        lines.append('receiver_os_info{key="%s",value="%s"} 1' % (label(key), label(value)))
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--listen', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=9101)
    parser.add_argument('--heartbeat', default='/var/lib/home-monitoring/renderer-success')
    parser.add_argument('--stale-after', type=int, default=900)
    parser.add_argument('--disk-path', action='append', default=None,
                        help='Filesystem path to measure; may be repeated (default: /)')
    parser.add_argument('--disk-interval-minutes', type=float, default=5,
                        help='Minimum minutes between disk usage reads (default: 5)')
    parser.add_argument('--os-info', default='/etc/os-info',
                        help='Path to the operating-system information file')
    args = parser.parse_args()

    heartbeat = args.heartbeat
    disk_cache = DiskUsageCache(args.disk_path or ['/'], args.disk_interval_minutes)

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != '/metrics':
                self.send_error(404)
                return
            body = metrics(heartbeat, args.stale_after, disk_cache, args.os_info).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; version=0.0.4')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args):
            pass

    ThreadingHTTPServer((args.listen, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
