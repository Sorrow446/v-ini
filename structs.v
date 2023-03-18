module vini

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