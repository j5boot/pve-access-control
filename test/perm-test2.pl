#!/usr/bin/perl -w

use strict;
use PVE::Tools;
use PVE::AccessControl;
use PVE::RPCEnvironment;
use Getopt::Long;

my $rpcenv = PVE::RPCEnvironment->init('cli');

my $cfgfn = "test2.cfg";
$rpcenv->init_request(userconfig => $cfgfn);

sub check_roles {
    my ($user, $path, $expected_result) = @_;

    my @ra = PVE::AccessControl::roles($rpcenv->{user_cfg}, $user, $path);
    my $res = join(',', sort @ra);

    die "unexpected result\nneed '${expected_result}'\ngot '$res'\n"
	if $res ne $expected_result;

    print "ROLES:$path:$user:$res\n";
}

# inherit multiple group permissions

check_roles('User1@pve', '/', '');
check_roles('User2@pve', '/', '');

check_roles('User1@pve', '/vms', 'Role1,Role2');
check_roles('User2@pve', '/vms', '');

check_roles('User1@pve', '/vms/100', 'Role1,Role2');
check_roles('User2@pve', '/vms', '');

print "all tests passed\n";

exit (0);
