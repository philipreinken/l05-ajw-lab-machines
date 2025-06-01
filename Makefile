
.PHONY: apply inventory.yaml

inventory-macs.txt: inventory-macs.txt.asc
	gpg --decrypt $< > $@

inventory.yaml: inventory.sh inventory-macs.txt
	bash $< > $@

files/darc/DARC_Raute.jpg: files/DARC_Logo_und_Raute.zip # https://www.darc.de/presse/downloads/#c154010
	unzip -o $< -d files/darc

files/wallpaper.png: files/darc/DARC_Raute.jpg
	convert $< -resize 500x500 -background white -gravity center -extent 1920x1080 -font "/usr/share/fonts/truetype/roboto/unhinted/RobotoCondensed-Bold.ttf" -pointsize 36 -fill gray -draw "text 0,300 'L05'" $@

apply: inventory.yaml
	ansible-playbook -i inventory.yaml playbook.yaml
