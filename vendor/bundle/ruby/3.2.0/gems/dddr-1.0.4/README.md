![Alt text](hero.png)

# DDDr: Domain Driven Design Repository

## Overview

"DDDr" is a Ruby gem designed to simplify the implementation of data repositories in a Domain-Driven Design (DDD) architecture. It provides a clean, easy-to-use interface for abstracting data access, so you can focus on domain logic rather than database operations.

## Features

* Easy-to-use Entity and Repository classes
* Built-in UUID generation for entities
* In-memory storage using SDBM
* Date and time tracking for entities
* CRUD operation support
* Extensible query and association methods

## Installation

To install, add the gem to your application's @Gemfile@:

<pre>
gem 'dddr'
</pre>

Then run:

<pre>
bundle install
</pre>

Alternatively, you can install the gem manually:

<pre>
gem install dddr
</pre>

## Usage

### Creating an Entity

Include the @Dddr::Entity@ module in your class:

<pre>
class MyEntity
  include Dddr::Entity
  attr_accessor :name, :email
end
</pre>

### Using the Repository

<pre>
repository = MyEntity::Repository.new
entity = MyEntity.new
entity.name = "John Doe"
entity.email = "john.doe@example.com"

# Adding the entity
uid = repository.add(entity)

# Updating the entity
entity.name = "Jane Doe"
updated_entity = repository.update(entity)

# Deleting the entity
repository.delete(entity)

# Fetching an entity by UID
fetched_entity = repository.get(uid)
</pre>

### Custom Queries

Define custom queries using the @queries@ method within your entity class.

<pre>
class MyEntity
  include Dddr::Entity
  attr_accessor :name, :email

  queries do
    def find_by_email(email)
      # Custom query logic here
    end
  end
end
</pre>

You can then execute the custom query like this:

<pre>
repository = MyEntity::Repository.new
repository.find_by_email("john.doe@example.com")
</pre>

