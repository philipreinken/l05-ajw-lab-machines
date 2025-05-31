
inventory-macs.txt: inventory-macs.txt.asc
	gpg --decrypt $< > $@

inventory.yaml: inventory.sh inventory-macs.txt
	bash $< > $@

apply: inventory.yaml
	ansible-playbook -i inventory.yaml playbook.yaml