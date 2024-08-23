# Contributing

## Setup

### Guide Book

[Install mdBook](https://rust-lang.github.io/mdBook/guide/installation.html).

See [the guide](https://rust-lang.github.io/mdBook/) to learn how mdBook works.

## Local Testing

When working on the guidebook, run `mdbook` in the book directory to get a live-updating hosted version of the book:

```sh
mdbook serve --open
```

The book image can be built from the book directory with:

```sh
make docker-build
```

## Adding a Scenario

1. Start mdBook in the `guidebook` directory (`mdbook serve --open` or use `make serve`)
2. Add an entry in [the SUMMARY file](./guidebook/src/SUMMARY.md) for your new scenario, and save the file. mdBook will automatically create a new file for you
3. Fill out the scenario entry. The page will be updated live by mdBook every time you save.
4. Add any new modules to the `modules` directory, if necessary. **Make sure to add the label `managed-by: spyderbat-eval` to all resources to ensure they are detected when updating, and to place everything within a separate labeled namespace.**
5. Update `scripts/access.sh` with any new port-forward commands needed to access resources for the scenario.
6. Update `scripts/install.sh` and `scripts/update.sh` with any new commands needed to create or update resources.

### Publishing the Updates

1. Update the guidebook image by merging into the main branch and creating a new release
2. Run the `scripts/update.sh` script with any clusters that need updating

## Scripts

See [Scripts](./scripts/README.md)
