# travis-core

[![Build Status](https://api.travis-ci.org/final-ci/travis-core.png?branch=master)](https://travis-ci.org/final-ci/travis-core)

Travis Core (or travis-core) contains shared code among different Travis CI applications.

See the [README in lib/travis](lib/travis) for more information on the structure of the repository.

## Contributing

Travis Core requires PostgreSQL 9.3 or higher, as well as a recent version of Redis and RabbitMQ.

### Repository setup

1. Clone the repository: `git clone https://github.com/travis-ci/travis-core.git`
1. Install gem dependencies: `cd travis-core; bundle install --binstubs --path=vendor/gems`
1. Set up the database: `bin/rake db:create db:structure:load`
1. Link the `logs` table migration to the proper place and perform DB migration:
```sh-session
pushd db/migrate
ln -svf ../../spec/migrations/*
popd
bin/rake db:migrate
git checkout -- db/structure.sql
```

Repeat the database steps for `RAILS_ENV=test`.
```sh-session
RAILS_ENV=test bin/rake db:create db:structure:load
RAILS_ENV=test bin/rake db:migrate
git checkout -- db/structure.sql
```

### Running tests

To run the RSpec tests, first make sure PostgreSQL, Redis and
RabbitMQ are running, then do:

```
./build.sh
```

Individual specs can be run with `bin/rspec`; e.g.,

```
bundle exec rspec spec/travis/model/job_spec.rb
```

### Submitting patches

Please fork the repository and submit a pull request. For larger changes, please open a ticket on our [main issue tracker](https://github.com/travis-ci/travis-ci/issues) first.

