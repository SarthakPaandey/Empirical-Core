## Documentation Table of Contents

- [API Controllers](https://github.com/empirical-org/Empirical-Core/blob/develop/app/controllers/api/README.md)
- [Authentication Controllers](https://github.com/empirical-org/Empirical-Core/blob/develop/app/controllers/auth/README.md)
- [Clever Integration](https://github.com/empirical-org/Empirical-Core/blob/develop/app/services/clever_integration/README.md)
- [CMS controllers](https://github.com/empirical-org/Empirical-Core/blob/develop/app/controllers/cms/README.md)
- [Google Integration](https://github.com/empirical-org/Empirical-Core/blob/develop/app/services/google_integration/README.md)

# Welcome to QuillLMS

QuillLMS is the Learning Management System that powers Quill.org, a free writing tool. QuillLMS is part of Empirical-Core, our web app for managing students, assigning activities, and viewing results

**Fork and Clone this repository to submit a Pull Request**

## Install QuillLMS

### MacOS Install Instructions

In your terminal:

1. Clone the Empirical Core repo `git clone https://github.com/empirical-org/Empirical-Core.git`
2. Navigate to LMS directory: `cd services/QuillLMS`
3. (recommended) Install [Postgres.app](https://postgresapp.com/) 
   - install the binary
   - create a postgresql v15 server through the Postgres.app GUI and start it
4. Run install script: `sh bin/dev/bootstrap.sh`
5. Open your browser to [localhost:3000](http://localhost:3000), the app should be running.

### Manual Install Instructions

QuillLMS is the Learning Management System that powers Quill.org. It is part of Empirical-Core Here's how to get QuillLMS running on your system:

2. Download and install [rbenv](https://github.com/sstephenson/rbenv) (or another Ruby version manager of your choice). You need to have Ruby version 3.1.4 installed in order to use Empirical Core. The best way to make sure you have version 3.1.4 is to follow the README and wiki of the Ruby version manager that you download. (You can check the .ruby-version file to find out the latest ruby version we are using in case this readme is out of date).

   If you decide to use rbenv, then [homebrew](http://brew.sh/) has a really great and easy-to-use setup and install process:

   1. `brew update`
   2. `brew install rbenv ruby-build`
   3. `echo 'eval "$(rbenv init -)"' >> ~/.bash_profile`
   4. Close and reopen your terminal.

2. Download and install [postgres](http://www.postgresql.org/) version 15.6, the database engine Empirical Core uses. The easiest way to get started with this is to download [postgres.app](http://postgresapp.com/).

   If you're more comfortable with installing custom software, you can use [homebrew](http://brew.sh/) to download and install postgres instead using the following commands:

   1. `brew update`
   2. `brew install postgres`
   3. Follow the instructions on the resulting info screen.

3. Install Redis. You can [download it directly](http://redis.io/download).

   Alternatively, you can use [homebrew](http://brew.sh/) to install it by running `brew install redis`.

4. Navigate to the directory where you'd like Empirical Core to live, then run the following command to clone the Empirical Core project repository:

   `git clone https://github.com/empirical-org/Empirical-Core.git`

5. Use `cd Empirical-Core/services/QuillLMS` to change directory into the QuillLMS service.

6. Install bundler with `gem install bundler`.

7. Set bundle config, needed for sidekiq-pro
```
export BUNDLE_GEMS__CONTRIBSYS__COM=$(heroku config:get BUNDLE_GEMS__CONTRIBSYS__COM -a empirical-grammar)
bundle config --local gems.contribsys.com $BUNDLE_GEMS__CONTRIBSYS__COM
```


7. Install the bundle with `bundle install`.

8. Troubleshooting unicode 0.4.4.4: on an M1 mac, you may need to install the unicode gem with the following flag: 
`gem install unicode -- --with-cflags="-Wno-incompatible-function-pointer-types"` 
From [stack overflow](https://stackoverflow.com/questions/78129921/gemextbuilderror-error-failed-to-build-gem-native-extension-unicode-c1058)

8. Install node via [nvm](https://github.com/creationix/nvm#installation). Run `nvm install` to install the version of node used by this app.
Note: check that the `.nvmrc` file has the same version of node as in the `package.json` file. 

9. Install npm by running `brew install npm`

10. Install node modules by running `npm install`

10. Copy the environment `cp -n .env-sample .env`

11. You'll have to manually add BIGQUERY_CREDENTIALS from the heroku empirical-grammer-staging Config Vars

12. Install [pgvector](https://github.com/pgvector/pgvector?tab=readme-ov-file#installation-notes---linux-and-mac)
11. Run `bundle exec rake empirical:setup` to automagically get all of your dependencies and databases configured.

13. You're ready to run QuillLMS! Switch back into the QuillLMS directory 

    1. Run the server using the command `foreman start -f Procfile.dev`
      - Note: if you get the error `Failed listening on port 7654 (TCP)` it means there is an extra redis instance running. You can run `lsof -i :7654` and then kill the redis process. 
      - Note 2: if you get an error on port 5000, and you're on a mac, it may be your airplay server which you'll have to turn off. See [this post](https://nono.ma/port-5000-used-by-control-center-in-macos-controlce) for info. 
    2. Navigate your browser to [localhost:3000](http://localhost:3000).
    3. When you're done with the server, use Ctrl-C to break it and return to your command line.

In case you are unable to start QuillLMS on your computer, please submit and issue. If you found a work around, we would also love to read your suggestions!

For more information on setting up and launching QuillLMS, visit the [docs](https://docs.quill.org/misc/setting_up.html).

## Test Suite

- backend
- you will need to populate the .env file with `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, 
`ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` and `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` by following instructions in that file. 

```ruby
bundle exec rspec spec
```

- frontend
  - ESLint: from the root directory run `npm run eslint`
  - Tests: `npm run jest`
   - See [test runner here](https://github.com/empirical-org/Empirical-Core/blob/ab24342ffe8064e9eb5154573d5937f9dc54f84c/services/QuillLMS/package.json#L20)
   - For an individual test you can run: `npm run jest [text]` which will just wildcard whatever the text is -- so if I want to run all the tests in Connect I just run npm run jest Connect.
   - `npm run jest [your/file/path]`

## Deployment

```bash
bash deploy.sh staging|staging2|sprint|prod
```

## Infrastructure

[staging (Heroku)](https://dashboard.heroku.com/apps/empirical-grammar-staging)
[staging 2 (Heroku)](https://dashboard.heroku.com/apps/empirical-grammar-staging2)
[sprint (Heroku)](https://dashboard.heroku.com/apps/quill-lms-sprint)
[production (Heroku)](https://dashboard.heroku.com/apps/empirical-grammar)
