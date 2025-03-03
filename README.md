# Squiggle

[![Packages check](https://github.com/quantified-uncertainty/squiggle/actions/workflows/ci.yml/badge.svg)](https://github.com/quantified-uncertainty/squiggle/actions/workflows/ci.yml)
[![npm version](https://badge.fury.io/js/@quri%2Fsquiggle-lang.svg)](https://www.npmjs.com/package/@quri/squiggle-lang)
[![npm version](https://badge.fury.io/js/@quri%2Fsquiggle-components.svg)](https://www.npmjs.com/package/@quri/squiggle-components)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/quantified-uncertainty/squiggle/blob/develop/LICENSE)
[![codecov](https://codecov.io/gh/quantified-uncertainty/squiggle/branch/develop/graph/badge.svg?token=QRLBL5CQ7C)](https://codecov.io/gh/quantified-uncertainty/squiggle)

This is an experimental DSL/language for making probabilistic estimates. The full story can be found [here](https://www.lesswrong.com/s/rDe8QE5NvXcZYzgZ3).

## Our deployments

- **website/docs prod**: https://squiggle-language.com [![Netlify Status](https://api.netlify.com/api/v1/badges/2139af5c-671d-473d-a9f6-66c96077d8a1/deploy-status)](https://app.netlify.com/sites/squiggle-documentation/deploys)
- **website/docs staging**: https://develop--squiggle-documentation.netlify.app/
- **components storybook prod**: https://squiggle-components.netlify.app/ [![Netlify Status](https://api.netlify.com/api/v1/badges/b7f724aa-6b20-4d0e-bf86-3fcd1a3e9a70/deploy-status)](https://app.netlify.com/sites/squiggle-components/deploys)
- **components storybook staging**: https://develop--squiggle-components.netlify.app/
- **legacy (2020) playground**: https://playground.squiggle-language.com

## Packages

This monorepo has several packages that can be used for various purposes. All
the packages can be found in `packages`.

- `@quri/squiggle-lang` in `packages/squiggle-lang` contains the core language, particularly
  an interface to parse squiggle expressions and return descriptions of distributions
  or results.
- `@quri/squiggle-components` in `packages/components` contains React components that
  can be passed squiggle strings as props, and return a presentation of the result
  of the calculation.
- `@quri/squiggle-website` in `packages/website` The main descriptive website for squiggle,
  it is hosted at `squiggle-language.com`.

The playground depends on the components library which then depends on the language. This means that if you wish to work on the components library, you will need to build (no need to bundle) the language, and as of this writing playground doesn't really work.

# Develop

For any project in the repo, begin by running `yarn` in the top level

```sh
yarn
```

See `packages/*/README.md` to work with whatever project you're interested in.

# Contributing

See `CONTRIBUTING.md`.
