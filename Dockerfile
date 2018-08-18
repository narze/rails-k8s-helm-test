FROM ruby:2.5-slim-stretch
MAINTAINER noom@eventpop.me

ENV APP_ROOT /app
ENV BUNDLE_PATH /usr/local/bundle

RUN apt-get update -qq && \
  apt-get install -y build-essential libpq-dev curl

# Node.js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y nodejs

RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile* ./
# RUN bundle config --global frozen 1
RUN bundle install -j4 --retry 3 \
  # Remove unneeded files (cached *.gem, *.o, *.c)
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete

COPY package.json ./
# COPY package.json yarn.lock .yarnclean /app/
RUN npm install -g yarn

RUN yarn install

ADD . ./

RUN bundle exec rake assets:precompile

EXPOSE 3000

ENV RAILS_ENV production

# ENV DOCKERIZE_VERSION v0.6.0
# RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
#   tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
#   rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
