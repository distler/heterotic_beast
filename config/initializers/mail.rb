##Choose the method for delivering signup emails
# Don't override the test environment, which sets delivery_method = :test
# in config/environments/test.rb so deliveries accumulate in
# ActionMailer::Base.deliveries instead of attempting SMTP.
ActionMailer::Base.delivery_method = :smtp unless Rails.env.test?

##Configuration for using an SMTP server 
ActionMailer::Base.smtp_settings = {
 :address               => "localhost",
 :port                  => 25,
# :domain                => "mydomain.com",
# :user_name             => "mailbox_user",
# :password              => "mailbox_password",
# :authentication        => :cram_md5, # or :plain or :login
 :enable_starttls_auto  => false
}

##Configuration for using sendmail
ActionMailer::Base.sendmail_settings = {
  :location   => '/usr/sbin/sendmail',
  :arguments  => '-i -t'
}
