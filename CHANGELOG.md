# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Last updated 10.12.2020

## [0.12.0] 10.12.2020
### Fixed
- Compatability with gdk_pixbuf v3.4.0+ [TECH-14001]
### Aded
- .ruby-version file


## [0.11.3] 26.06.2019
### Fixed
- Compatability with gdk_pixbuf v3.0.9+ [TECH-9065]

## [0.11.2] 21.02.2019
### Added
- While throwing Gdk::PixbufError::CorruptImage in Morandi::ProfiledPixbuf#initialize try to recover the image by saving it to a tempfile and re-read. This operation should remove all wrong markers. [TECH-7663]

## [0.11.1] 21.02.2019
### Added
- Have option to set the JPEG image compression size be a string like all the other options. [TECH-7701]

## [0.11.0] 07.12.2018
### Added
- Added option to set the JPEG image compression size [104324]
