FROM ruby:3.3-slim

LABEL Name=morandirb Version=0.0.2

RUN apt-get update && apt-get install -yyq --no-install-recommends \
  build-essential \
  libglib2.0-dev \
  libcairo2-dev \
  libgdk-pixbuf2.0-dev \
  imagemagick \
  liblcms2-utils \
  # When girepository tries to install implicitly, there's an error due to apt being locked; details in commit message
  libgirepository1.0-dev \
  # At the time of writing, "time" package is only required for benchmark
  time \
  && apt-get clean \
  && rm -rf /va/lib/apt/lists/*

RUN gem update --system 3.4.22

WORKDIR /app
COPY morandi.gemspec Gemfile Gemfile.lock ./
COPY lib/morandi/version.rb lib/morandi/version.rb
RUN bundle install
COPY . /app
# Compile the native extensions
RUN bundle exec rake compile

CMD ["bundle", "exec", "guard"]
