##Configuration for using an SMTP server 
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
 :address               => "localhost",
 :port                  => 25,
# :domain                => "mydomain.com",
# :user_name             => "mailbox_user",
# :password              => "mailbox_password",
# :authentication        => :cram_md5, # or :plain or :login
 :enable_starttls_auto => false
}
##Configuration for using sendmail
#ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.sendmail_settings = {
#  :location => '/usr/sbin/sendmail',
#  :arguments => '-i -t'
#}
