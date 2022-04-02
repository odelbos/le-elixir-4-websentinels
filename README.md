# Synopsis

This repository is an Elixir learning exercise.

**Disclaimer : Do not use this code in production.**

## Subject of the exercise

The subject of this exercise is to play with OTP : `GenServer`, `Supervisor`.

Periodically ping HTTP requests and verify if some expectations are met.  
_(fancy pingdom, betteruptime)_

If the expectations fail then send a `Pushover` alert.  
_(read more for about the service : [Pushover](https://pushover.net/))_

## Setup

```sh
mix deps.get
```

Copy the YAML configuration file and edit them to suit your needs:

```sh
cd config
cp SAMPLE.sentinels.yml sentinels.yml
cp SAMPLE.pushover.yml pushover.yml
```

Run the application:

```sh
mix run --no-halt
```

## Sentinels configuration

Example of the sentinels YAML configuration file:

```yaml
#
# The minimal information to provide for a sentinel:
# (the url, the interval time of each request, the expected http status code) 
#
- url: https://my-website-1.com                         # URL to ping
  every: 2h                                             # Check every 2h
  expects:
    status: 200                                         # Expected HTTP status 200

#
# Full sample with all possible expectations:
#
- url: https://my-website-1.com/pageA.html              # URL to ping
  every: 1mn                                            # Check every 1mn
  expects:
    status: 200                                         # Expected HTTP status 200
    max_duration: 2000                                  # Request duration must be < 2000ms
    length:
      - { value: 500, op: ">" }                         # Body length must > 500 bytes
      - { value: 3500, op: "<" }                        # Body length must < 3500 bytes
      - { value: 2990, op: "=" }                        # Body length must equals to 2990 bytes
    body:
      - { value: "Foo", op: "c" }                       # Body must contains the string "Foo"
      - { value: "ok", op: "=" }                        # Body must be equals to the string "ok"
      - { value: "45472e018aa13b55dfcf510336049b7e", op: "md5" }   # Body md5 must be equals to 4547....9b7e
    headers:
      - { name: "csrf-token", op: "?" }                          # Header "csrf-token" must be present (no matter his value)
      - { name: "content-type", value: "text/html", op: "c" }    # Header "content-type" must contains "text/html"
      - { name: "content-type", value: "text/html;charset=utf-8", op: "=" }   # Header "content-type" must be equals to
      - { name: "content-length", value: 500, op: ">" }          # Header must be > to 500
      - { name: "content-length", value: 3000, op: "<" }         # Header must be < to 3000
      - { name: "content-length", value: 2991, op: "=" }         # Header must be = 2991

- url: https://my-website-2.com
  every: 5mn
  expects:
    status: 401
    max-duration: 500
```

* The `every` attribute format can be in minutes or hours:

  * `<int>mn` : 1mn, 12mn, 38mn
   * `<int>h` : 1h, 3h, 12h

* `max_duration` is in milliseconds

* For the header expectations when using the operators `>`, `<` or `=`, the value of the header must an integer or can be converted to integer."