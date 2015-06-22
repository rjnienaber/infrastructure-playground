#!/usr/bin/env bash
curl http://127.0.0.1:4567/execute_trade?sleep=3 &
sleep 1
curl http://127.0.0.1:4567/execute_trade?sleep=0.1 &

