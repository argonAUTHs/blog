---
title: Yet another data migration problem
date: 2015-08-13T13:19:28+02:00
author: blelump
comments: true
layout: post
tags:
  - PostgreSQL
  - data migration
---

**TL;DR** _Ensure data consistency while copying data across databases having RDBMS (PostgreSQL in this case) on board._

### The problem 

Imagine you have two databases, such a they've had the same parent in the past. As the time goes by, some of the data might change in any of them. Now, you'd like to copy object A between databases under assumption that it's only going to create a copy if there's no equal object in the destination database. The object might contain foreign keys and such associations are also considered during checking equality.

### Considerations

The easiest solution you'd think of is dump the data you want and then restore in destination database. Such approach, however, implies that you'd need a tool taking only data you want to copy. Not the whole database or table, only object A with its associations. PostgreSQL provides [pg_dump][1] or [copy][2] for data migrations, however none of them lets you deal with associations easily. You'd then use some higher level tools, e.g. any ORM you like and deal with _deep_ object copy itself. 

To check for equality, you'd need some data to compare. The best candidate would be to compare record `id` and its foreign keys. In this case however, you're guaranteed that `id` in database X and Y points to the same record. They may differ and result in a mess. 

##### Check for hash(database_X(A)) == hash(database_Y(A))

Another approach would be to calculate a hash of the data you'd like to compare and then use hashes instead of ids. So if the result matches, you'd not need to make a copy and for further operations, you'd just use record id. 

#### Build a hash of record

To build a hash, you'd add a trigger to your database with appropriate function, e.g:
{% highlight plpgsql %}
CREATE OR REPLACE FUNCTION update_post_footprint_func()
RETURNS trigger AS $$
DECLARE raw_footprint text;
BEGIN

raw_footprint := concat(NEW.title, NEW.content, NEW.owner_id);
NEW.footprint := (SELECT md5(raw_footprint));

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_post_footprint BEFORE INSERT OR UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE update_post_footprint_func();
{% endhighlight %}

Such function will build new hash for given record for each insert or update. As you'd notice, this use case considers only 1 x 1 relationship at most and doesn't cover 1 x N. For instance, a post record might have many tags. In this case you have two choices, either select for footprints of the dependencies (note that it implies any dependency has its own footprint), e.g:
{% highlight plpgsql %}
raw_footprint := concat(...,
(select array_to_string(array(select footprint from tags where post_id = NEW.id order by id ASC), '|')));
{% endhighlight %}

or build parent footprint based on the dependency data, e.g:
{% highlight plpgsql %}
raw_footprint := concat(...,
(select array_to_string(array(select name from tags inner join post_tags on tags.id = post_tags.tag_id where post_tags.post_id = NEW.id order by id ASC), '|')));
{% endhighlight %}


The footprint build process is somewhat similar to the [Russian Doll][3] caching pattern, despite you need to be aware that dependencies footprint must be built before the record footprint. However, it only applies when refering dependency footprints directly. 

### Possible issues

1. Depending on the record dependencies, there might be a need to build a few/several triggers, where each generates sub-footprint, finally assembled with the main footprint.
2. The speed. Since each trigger execution is a non-zero time consuming operation, the need of using it should be further discussed and associated with the use case. If it's going to be rarely used and data insertions/updates are heavy, perhaps it would be a better idea to use it within the app itself.


[1]: http://www.postgresql.org/docs/current/static/backup-dump.html
[2]: http://www.postgresql.org/docs/current/interactive/sql-copy.html
[3]: http://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching
