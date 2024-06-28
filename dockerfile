# syntax = docker/dockerfile:1
FROM ruby:2.7.8

# Install packages needed to build gems
RUN apt-get update -qq && \
apt-get install -y build-essential default-libmysqlclient-dev libvips curl default-mysql-client

WORKDIR /railschat

ENV RAILS_ENV="development" \
BUNDLE_DEPLOYMENT="1" \
BUNDLE_PATH="/usr/local/bundle" \
RUBYOPT=-W:no-deprecated

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

RUN chmod +x /railschat/bin/docker-entrypoint
# Entrypoint prepares the database.
ENTRYPOINT ["/railschat/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ./bin/rails server --binding 0.0.0.0