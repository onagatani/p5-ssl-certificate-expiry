#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode;
use Pod::Usage;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Net::SSLeay qw(sslcat);
use DateTime;
use DateTime::Format::Strptime;
use Data::Recursive::Encode;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

GetOptions(
    "host=s"    => \my $host,
    "days=s"    => \my $days,
    "to=s"      => \my $to,
    "from=s"    => \my $from,
);

my $subject = "$host is ssl certificate expiry";

pod2usage() unless $host;

checker();

sub checker {

    my @cert = sslcat($host, '443', undef);

    my $rv = Net::SSLeay::X509_get_notAfter($cert[2]);

    my $date = Net::SSLeay::P_ASN1_TIME_put2string($rv);

    my $tz = DateTime::TimeZone->new('name' => 'local');

    my $strp = DateTime::Format::Strptime->new(pattern => "%b %d %T %Y %Z");

    my $dt = $strp->parse_datetime($date);

    $dt->set_time_zone($tz);

    my $now = DateTime->now( time_zone=> $tz );

    my $dur = $dt->delta_days($now);

    my $limit_days = $dur->in_units('days');

    print STDOUT $limit_days . "\n";

    if ($limit_days < $days) {
        alert($limit_days);
    }
}

sub alert {
    my $limit_days = shift;

    my $body = "$limit_days";

    my $email = Email::Simple->create(
        header => Data::Recursive::Encode->encode(
            'MIME-Header-ISO_2022_JP' => [
                To      => $to,
                From    => $from,
                Subject => $subject,
            ]
        ),
        body       => encode( 'iso-2022-jp', $body ),
        attributes => {
            content_type => 'text/plain',
            charset      => 'ISO-2022-JP',
            encoding     => '7bit',
        },
    );

    sendmail($email);
}

1;
__END__

=encoding utf-8

=head1 NAME

ssl-certificate-expiry

=head1 DESCRIPTION

SSL certificate expiry

=head1 SYNOPSIS

ssl-certificate-expiry [options]

ssl-certificate-expiry --host=www.google.co.jp --days=30 --to=alert@example.com --from=from@example.com

 Options:
    --host fqdn 
    --days If you exceed the limit number of days send mail
    --to to email address
    --from from email address

