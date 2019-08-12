# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.3] - [2018-07-12]

### Fixes
Extractors should be copied during inheritance but children should not be able to modify the parents' @extractors.

## [0.1.2] - [2018-07-18]

### Fixes
Deep inheritance of BC::Ext::Refined was broken, fixed that

## [0.1.1] - [2018-07-10]

### Fixes:
Aliases for `#or_a` and `#and_then` didn't work well for BC::Ext::Refined

## [0.1.0] - [2019-07-04]

This is a first public release marked in change log with features extracted from production app.
Includes:
- *BC::Ext::Refined* - exteneded refinement type with support of Extractors and Policy for validation
- *Extractable* - is a simple concern that turns your refinement type into a coercer which tries to extract particular fields from the given value,
  the bonus is that you need no #match method definition, only methods that you passed to `.extract` DSL
- *MapValue* - is a type which saves the value in the original form to context and then passes it some mapper class, which should change the
  form of the input object (e.g. turn it into JSON or XML)
- *ExpectedError* - is a validation scenario when something goes wrong during validation but in expected way (e.g. API returns a recoverable error),
  that type is valid too, but `#unpack` returns a Tram::Policy::Errors
- *DefinableError* - is a concern to define single time Tram::Policy::Errors, when you don't want to delegate validation to policy, but you want
  to store errors in form of Tram::Policy::Errors
- *ExceptionCaught and ExceptionHandling* - is a way to turn StandardError inside the type matching into another refinement type, that type is of course
  ancestor of BC::ContractFailure, but have an additional reader `#exception` which gives you access to the exception and at the same time you could
  read all the context that was collected till the "exceptional" moment
