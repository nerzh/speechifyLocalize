# SpeechifyLocalize

### Install

```bash
git clone git@github.com:nerzh/speechifyLocalize.git

cd speechifyLocalize

run: $swift build -c release

find the exec here, in the repo's folder (enable hidden folders): ./.build/arm64-apple-macosx/release/speechifyLocalize
```


speechifyLocalize -h

### Parser
speechifyLocalize parser -h

speechifyLocalize parser --project-path  /path_to_project/with_swift_files

speechifyLocalize parser --localization-path  /path_to_directory_with_name.lproj_folders

example:

speechifyLocalize parser --project-path  /path_to_project/with_swift_files --localization-path /path_to_directory_with_name.lproj_folders 
### Converter

speechifyLocalize converter -h

speechifyLocalize converter --localization-path /path_to_directory_with_name.lproj_folders

speechifyLocalize converter --table-file-path /path_to_csv_file_with_name.csv

speechifyLocalize converter --export-csv

speechifyLocalize converter --import-csv

example:

speechifyLocalize converter --localization-path /path_to_directory_with_name.lproj_folders --table-file-path /path_to_csv_file_with_name.csv --export-csv

speechifyLocalize converter --localization-path /path_to_directory_with_name.lproj_folders --table-file-path /path_to_csv_file_with_name.csv --import-csv


### Validator

speechifyLocalize validator -h

speechifyLocalize validator --project-path  /path_to_project/with_swift_files

speechifyLocalize validator --localization-path /path_to_directory_with_name.lproj_folders

example:

speechifyLocalize validator --project-path /path_to_project/with_swift_files --localization-path /path_to_directory_with_name.lproj_folders 
