SHELL := /bin/bash
# Ask redis for all the buckets.
# `make objects buckets=12` only updates bucket 12
buckets = $$(redis-cli keys 'object:*' | egrep 'object:[0-9]+$$$$' | cut -d ':' -f 2 | sort -g)

objects:
	for bucket in $(buckets); do \
		echo $$bucket; \
		[[ -d objects/$$bucket ]] || mkdir objects/$$bucket; \
		redis-cli --raw hgetall object:$$bucket | grep -v "<br />" | while read id; do \
			if [[ $$id = *[[:digit:]]* ]]; then \
				read -r json; \
				echo "$$json" | jq --sort-keys '.' > objects/$$bucket/$$id.json; \
			fi; \
		done \
	done
	ag -l '%C2%A9|%26Acirc%3B%26copy%' objects/ | xargs sed -i'' -e 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g'

git: objects
	git add objects/
	git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"
	git push

count:
	find objects/* | wc -l

.PHONY: objects git count
