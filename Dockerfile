FROM ruby:2.6

ENV CSV_URL=
ENV DATABASE=
ENV SLACK_URL=

RUN mkdir /usr/src/app
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock /usr/src/app/
RUN gem install bundler -v 2.2.14
RUN bundle install

COPY . /usr/src/app/

RUN ln -s /usr/src/app/exe/exposure-bot /usr/bin/exposure-bot

CMD exposure-bot

