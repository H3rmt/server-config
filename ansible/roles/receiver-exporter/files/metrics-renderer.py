#!/usr/bin/env python3
"""Temporary renderer placeholder.

The real framebuffer dashboard renderer can replace this loop later. Until
then, it marks the renderer successful at a configurable interval so the
monitoring pipeline can be tested end-to-end.
"""
import argparse
import os
import time


def touch(path):
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    with open(path, 'a'):
        os.utime(path, None)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--heartbeat', default='/var/lib/home-monitoring/renderer-success')
    parser.add_argument('--interval-seconds', type=float, default=60)
    args = parser.parse_args()
    interval = max(1.0, args.interval_seconds)
    while True:
        touch(args.heartbeat)
        time.sleep(interval)


if __name__ == '__main__':
    main()
