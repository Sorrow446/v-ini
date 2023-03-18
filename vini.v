module vini

import os

const (
	allowed_sec_key_chars = 'abcdefghijklmnopqrstuvwxyz0123456789.-_/'
	allowed_key_chars = 'abcdefghijklmnopqrstuvwxyz0123456789.-_'
)

fn check_key(k string, section bool, line_num int) ! {
	mut key := k
	mut allowed_chars := allowed_sec_key_chars
	if !section {
		if key.starts_with('+') || key.starts_with('-') || key.starts_with('!') {
			key = key[1..]
		}
		allowed_chars = allowed_key_chars
	}

	for r in key.runes() {
		c := r.str().to_lower()
		if !allowed_chars.contains(c) {
			mut err_str := 'prohibited character "${c}" found in key "${key}"'
			if line_num > 0 {
				err_str += ' on line ${line_num+1}'
			}
			return error(err_str)
		}
	}
}

fn parse(lines []string) !&INIFile {
	mut cur_section_key := ''
	mut ini_file := &INIFile{}
	for line_num, line_ in lines {
		line := line_.trim_space()
		if line == '' {
			continue
		}

		first_char := line[..1]
		if first_char in [';', '#'] {
			continue
		}

		line_len := line.len
		last_char := line[line_len-1..]
		under_section := first_char == '[' && last_char == ']'
		if under_section {
			cur_section_key = line[1..line_len-1]
			check_key(cur_section_key, true, line_num)!
			if cur_section_key in ini_file.sections.keys() {
				return error('duplicate section key "[${cur_section_key}]" on line ${line_num+1}')
			}
			ini_file.sections[cur_section_key] = {}
		} else {
			split := line.split_nth('=', 2)
			if split.len != 2 {
				return error('invalid key/value')
			}
			key := split[0].trim_space()
			value := split[1].trim_space()
			check_key(key, false, line_num)!
			if cur_section_key == '' {
				if key in ini_file.loose.keys() {
					ini_file.duplicates.loose[key] << value
				} else { 
					ini_file.loose[key] = value
				}

			} else  {
				if key in ini_file.sections[cur_section_key].keys() {
					ini_file.duplicates.sections[cur_section_key][key] << value
				} else { 			
					ini_file.sections[cur_section_key][key] = value
				}
			}
		}
	}
	return ini_file
}

pub fn read(file_path string) !&INIFile {
	lines := os.read_lines(file_path)!
	return parse(lines)!
}

pub fn write(file_path string, ini_file &INIFile) ! {
	mut f := os.open_file(file_path, 'wb+', 0o755)!
	defer { f.close() }

	for k, v in ini_file.loose {
		check_key(k, false, 0)!
		f.write_string('${k}=${v}\n')!
		for duplicate_v in ini_file.duplicates.loose[k] {
			f.write_string('${k}=${duplicate_v}\n')!
		}
	}
	if ini_file.loose.len > 0 {
		f.write_string('\n')!
	}
	
	mut sec_num := 0
	sec_count := ini_file.sections.len

	for section_key, key_val_maps in ini_file.sections {
		sec_num++
		if section_key == '' {
			continue
		}
		check_key(section_key, true, 0)!
		f.write_string('[${section_key}]\n')!
		for k, v in key_val_maps {
			check_key(k, false, 0)!
			f.write_string('${k}=${v}\n')!
			for duplicate_v in ini_file.duplicates.sections[section_key][k] {
				f.write_string('${k}=${duplicate_v}\n')!
			}
		}

		if sec_num < sec_count {
			f.write_string('\n')!
		}	
	}
}