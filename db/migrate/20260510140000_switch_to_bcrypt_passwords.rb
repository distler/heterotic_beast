# Replace the legacy SHA-1 password digest (crypted_password + per-user
# salt, peppered by the leaked REST_AUTH_SITE_KEY) with a bcrypt
# password_digest column. Every existing user ends up with
# password_digest = NULL after this migration — they can't log in until
# they use the "E-mail me the link" reset flow on /login, click the
# emailed activation link, and set a new password on /settings.
#
# This is intentional: the pre-migration digests are based on a 14-year-
# old publicly-committed pepper and are not safe to keep around.

class SwitchToBcryptPasswords < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :password_digest, :string
    remove_column :users, :crypted_password
    remove_column :users, :salt
  end

  def down
    add_column    :users, :crypted_password, :string, limit: 40
    add_column    :users, :salt,             :string, limit: 40
    remove_column :users, :password_digest
  end
end
