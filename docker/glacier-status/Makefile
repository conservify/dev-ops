all:
	rsync -zvua --progress ~/glacier/ glacier/
	docker build --no-cache --rm -t conservify/glacier-status .
