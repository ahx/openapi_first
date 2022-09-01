# How to run these bechmarks

## Setup

```bash
cd benchmarks
bundle install
```

## Run Ruby benchmarks

This compares ips and memory usage for all apps defined in /apps

```bash
bundle exec ruby benchmarks.rb
```

## Run benchmark using [wrk](https://github.com/wg/wrk)

1. Start the example app
Example: openapi_first
```bash
bundle exec puma apps/openapi_first_with_response_validation.ru
```

2. Run wrk
```bash
./benchmark-wrk.sh
```
