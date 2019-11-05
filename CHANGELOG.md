# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.8] - 2019-11-05
### Fixed
- Removed unnecessary ActionMailer class

## [0.4.7] - 2019-11-05
### Fixed
- Changed to config.eager_load_paths to try to avoid `ActiveTracker::Model` not defined in production

## [0.4.6] - 2019-11-05
### Fixed
- Fixed uninitialized constant error in production

## [0.4.3 - 0.4.5] - 2019-11-05
### Fixed
- Error during initial project database migration if activetracker is used

## [0.4.2] - 2019-11-05
### Fixed
- API-only projects don't have BetterErrors enabled apparently

## [0.4.1] - 2019-11-05
### Added
- Added support for API-only projects that don't have an asset pipeline

## [0.4.0] - 2019-11-04
### Release
- First public release
