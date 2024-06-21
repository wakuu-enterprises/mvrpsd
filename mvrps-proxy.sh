#!/bin/sh /etc/rc.common

# Init script for MVRPS proxy daemon

START=99
STOP=10

DAEMON=/usr/local/bin/mvrps-proxy
DAEMON_OPTS=""
PIDFILE=/var/run/mvrps-proxy.pid

start() {
    echo "Starting MVRPS proxy daemon..."
    start-stop-daemon --start --quiet --background --make-pidfile --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS
    echo "MVRPS proxy daemon started."
}

stop() {
    echo "Stopping MVRPS proxy daemon..."
    start-stop-daemon --stop --quiet --pidfile $PIDFILE
    rm -f $PIDFILE
    echo "MVRPS proxy daemon stopped."
}

restart() {
    stop
    start
}

boot() {
    start
}

shutdown() {
    stop
}
