## v1.1.2 [2019-04-15]

#### Release Notes

Set default port to `8094` which is default in telegraf when used
with `udp`, fix return of `set` method.

## v1.1.1 [2019-03-31]

#### Release Notes

Improved tests and error handling.

#### Bugfixes

- Field and tag values accepted table `type` which produced
`string` representation of table location.

## v1.1.0 [2019-03-23]

#### Release Notes

Implement batching.

#### Bugfixes

- Mistakenly every tag was added in `global_tags` table

## v1.0.0 [2018-12-13]

#### Release Notes

Initial release.
