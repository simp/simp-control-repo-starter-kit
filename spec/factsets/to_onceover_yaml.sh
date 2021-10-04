#!/bin/bash
# Rename files to common convention
for file in *.out *.json; do
   new_filename="$(jq '.values | [.role, .fqdn, .os.name, .os.release.major] | @tsv' "$file" -j | sed -e 's/\t/--/g' -e 's/--\([0-9]\+\)/-\1/' |xargs echo)"
   mv "$file" "${new_filename}.json"
done

nodes=($(ls -1 *.json | sed -e 's/.json$//' | sort -u))
roles=($(jq -r '.values.role' "${nodes[@]/%/.json}" | sort -u))


echo classes:
for i in "${roles[@]}"; do echo "  - role::$i"; done
echo

echo nodes:
for i in "${nodes[@]}"; do printf "  - %s\n" $i "$(ls -1 *$i*.json | sed -e 's/.json$//')"; done
echo

echo node_groups:
for i in "${roles[@]}"; do printf "  %s_nodes:\n  - %s\n" $i "$(ls -1 *$i*.json | sed -e 's/.json$//')"; done
echo
echo test_matrix:
for i in "${roles[@]}"; do printf "  - %s_nodes:\n      classes: role::%s\n      tests: 'spec'\n" $i $i; done

printf 'opts:\n  :manifest: 'manifests/site.pp'\n'
