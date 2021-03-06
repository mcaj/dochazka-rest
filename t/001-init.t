# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# - test initialization, among other things, by completely wiping the database

###
###
### This unit is special in that it resets the database.
### It should be called at the beginning of the regression test suite.
### Under certain circumstances it may generate warnings.
###
###

#!perl
use 5.012;
use strict;
use warnings;
use Test::More;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $CELL $site );
use App::Dochazka::REST;
use App::Dochazka::REST::ConnBank qw( $dbix_conn conn_status );
use App::Dochazka::REST::Test;
use Try::Tiny;
use Web::MREST;


note( 'initialize the REST server' );
my $status = Web::MREST::init( distro => 'App-Dochazka-REST', sitedir => '/etc/dochazka-rest' );
if ( $status->not_ok ) {
    diag( $status->text );
    plan skip_all => "Not configured. Please run the test suite manually after initial site configuration";
}

note( 'DOCHAZKA_TIMEZONE must be set' );
BAIL_OUT(-1) unless $site->DOCHAZKA_TIMEZONE;

note( 'reset the database to "factory state"' ); 
# * * * WARNING: THIS WIPES THE DATABASE * * *
# * * * ALL DATA IN IT WILL BE LOST      * * *
$status = App::Dochazka::REST::reset_db(
    $site->DBINIT_CONNECT_SUPERUSER,
    $site->DBINIT_CONNECT_SUPERAUTH,
);
if ( $status->not_ok ) {
    plan skip_all => "PostgreSQL server is unreachable";
}
ok( $status->ok, "Database dropped and re-created" );

note( 'initialize the $dbix_conn singleton' ); 
App::Dochazka::REST::ConnBank::init_singleton();

note( "get EID of root and demo users according to site configuration" );
ok( $site->DOCHAZKA_EID_OF_ROOT );
ok( $site->DOCHAZKA_EID_OF_DEMO );

note( 'get EID of root and demo users by database lookup' );
my $eids = App::Dochazka::REST::get_eid_of( $dbix_conn, "root", "demo" );
ok( $eids->{'root'} );
ok( $eids->{'demo'} );

note( 'compare that they are the same' );
is( $site->DOCHAZKA_EID_OF_ROOT, $eids->{'root'} );
is( $site->DOCHAZKA_EID_OF_DEMO, $eids->{'demo'} );

note( 'check that their values are 1 and 2, respectively' );
is( $eids->{'root'}, 1 );
is( $eids->{'demo'}, 2 );

note( 'check the conn_status value' );
is( conn_status(), "UP" );

done_testing;
