# Sampled Factsets

This directory contains sampled factsets that will be used to loop through in the control repository spec tests.

## Collecting facts from a sample host

1. On the sample system, run the following command:
```bash
  sudo /opt/puppetlabs/bin/puppet facts --environment production > $HOSTNAME.facts.json
```

2. Copy the `$HOSTNAME.facts.json` file into this directory under `host_data/`

3. Point a descriptive symlink in this directory to the file under `host_data/`

