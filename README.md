# v-ini
INI library for V.

## Setup
`v install Sorrow446.vini`
```v
import sorrow446.vini as ini
```

## Examples
#### Accessing values
```v
mut cfg := ini.read('1.ini')!
section := cfg.sections['config']
println(section['out_path'])
println(section['format'].int())
```
#### Read INI, modify it, then write it to a new file
```v
mut cfg := ini.read('1.ini')!
cfg.sections['config']['out_path'] = 'G:\\out2'
cfg.sections['new.section'] = {
  'ab': 'cd',
  'ef': 'gh',
}
```
```
[config]
out_path=G:\out
format=10
```
->
```
[config]
out_path=G:\out2
format=10

[new.section]
ab=cd
ef=gh
```

## Restrictions
|Type|Allowed chars|
| --- | --- |
|Section key|`a-zA-Z0-9.-_/`
|Key|`a-zA-Z0-9.-_`
|Value|any

- Loose key/value pairs without sections are allowed.
- Duplicate value keys are allowed, but duplicate section keys aren't.

## Structs
```v
pub struct Duplicates {
pub mut:
	sections map[string]map[string][]string
	loose	map[string][]string
}

pub struct INIFile {
pub mut:
	sections map[string]map[string]string
	loose map[string]string
	duplicates Duplicates
}
```
