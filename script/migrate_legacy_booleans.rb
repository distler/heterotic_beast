# One-shot migration: rewrite legacy SQLite "t"/"f" boolean values to 1/0
# and reset their column DEFAULTs to integer literals.
#
# This is a SQLite-only fix. When the DB was first populated under Rails 2
# the SQLite3 adapter stored booleans as "t"/"f" strings; Rails 5+
# switched to 1/0 integers, but pre-existing rows and the DDL `DEFAULT 't'`
# clauses didn't get migrated. MySQL (and PostgreSQL) have always
# represented BOOLEAN as 0/1 integers, so production DBs on those
# adapters are unaffected.
#
# Two layered problems on SQLite:
#   1. Existing rows have raw values "t"/"f". Rails 7 serializes
#      `where(admin: true)` as `WHERE admin = 1`, which doesn't match
#      "t" → silent mis-find.
#   2. The DDL itself had `DEFAULT 't'`. ActiveRecord's partial-write
#      optimization skips a column in the INSERT when the new value
#      matches the schema default — so even brand-new rows ended up
#      with SQLite filling in the literal `'t'` string default.
#      `change_column_default` here rewrites the column DDL with a
#      proper integer default.
#
# Run with: bundle32 exec rails runner script/migrate_legacy_booleans.rb

conn = ActiveRecord::Base.connection

unless conn.adapter_name.match?(/sqlite/i)
  puts "Skipping: not a SQLite database (adapter_name=#{conn.adapter_name})."
  puts "Other adapters (MySQL, PostgreSQL) have always stored booleans as 0/1."
  exit 0
end

conn.tables.each do |table|
  bool_cols = conn.columns(table).select { |c| c.sql_type == 'boolean' }
  bool_cols.each do |col|
    conn.execute(%{UPDATE #{table} SET #{col.name} = 1 WHERE #{col.name} = 't'})
    conn.execute(%{UPDATE #{table} SET #{col.name} = 0 WHERE #{col.name} = 'f'})

    # Reset the column default. `change_column_default` on SQLite
    # rebuilds the table; only do it if the current default looks
    # like a legacy string literal.
    if col.default.is_a?(String) && %w[t f].include?(col.default)
      new_default = col.default == 't'
      conn.change_column_default(table, col.name, from: col.default, to: new_default)
      puts "#{table}.#{col.name}: default '#{col.default}' → #{new_default}"
    else
      puts "#{table}.#{col.name}: rows normalized; default already #{col.default.inspect}"
    end
  end
end
