package PVE::API2::Group;

use strict;
use warnings;
use PVE::Cluster qw (cfs_read_file cfs_write_file);
use PVE::AccessControl;

use PVE::SafeSyslog;

use Data::Dumper; # fixme: remove

use PVE::RESTHandler;

use base qw(PVE::RESTHandler);

my $extract_group_data = sub {
    my ($data, $full) = @_;

    my $res = {};

    $res->{comment} = $data->{comment} if defined($data->{comment});

    return $res if !$full;

    $res->{users} = $data->{users} ? [ keys %{$data->{users}} ] : [];

    return $res;
};

# fixme: index should return more/all attributes?
__PACKAGE__->register_method ({
    name => 'index', 
    path => '', 
    method => 'GET',
    description => "Group index.",
    parameters => {
	additionalProperties => 0,
	properties => {},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => {
		groupid => { type => 'string' },
	    },
	},
	links => [ { rel => 'child', href => "{groupid}" } ],
    },
    code => sub {
	my ($param) = @_;
    
	my $res = [];

	my $usercfg = cfs_read_file("user.cfg");
 
	foreach my $group (keys %{$usercfg->{groups}}) {
	    my $entry = &$extract_group_data($usercfg->{groups}->{$group});
	    $entry->{groupid} = $group;
	    push @$res, $entry;
	}

	return $res;
    }});

__PACKAGE__->register_method ({
    name => 'create_group', 
    protected => 1,
    path => '', 
    method => 'POST',
    description => "Create new group.",
    parameters => {
   	additionalProperties => 0,
	properties => {
	    groupid => { type => 'string', format => 'pve-groupid' },
	    comment => { type => 'string', optional => 1 },
	},
    },
    returns => { type => 'null' },
    code => sub {
	my ($param) = @_;

	PVE::AccessControl::lock_user_config(
	    sub {
			
		my $usercfg = cfs_read_file("user.cfg");

		my $group = $param->{groupid};
	
		die "group '$group' already exists\n" 
		    if $usercfg->{groups}->{$group};

		$usercfg->{groups}->{$group} = { users => {} };

		$usercfg->{groups}->{$group}->{comment} = $param->{comment} if $param->{comment};

		
		cfs_write_file("user.cfg", $usercfg);
	    }, "create group failed");

	return undef;
    }});

__PACKAGE__->register_method ({
    name => 'update_group', 
    protected => 1,
    path => '{groupid}', 
    method => 'PUT',
    description => "Update group data.",
    parameters => {
   	additionalProperties => 0,
	properties => {
	    # fixme: set/delete members
	    groupid => { type => 'string', format => 'pve-groupid' },
	    comment => { type => 'string', optional => 1 },
	},
    },
    returns => { type => 'null' },
    code => sub {
	my ($param) = @_;

	PVE::AccessControl::lock_user_config(
	    sub {
			
		my $usercfg = cfs_read_file("user.cfg");

		my $group = $param->{groupid};
	
		my $data = $usercfg->{groups}->{$group};

		die "group '$group' does not exist\n" 
		    if !$data;

		$data->{comment} = $param->{comment} if $param->{comment};
		
		cfs_write_file("user.cfg", $usercfg);
	    }, "create group failed");

	return undef;
    }});

# fixme: return format!
__PACKAGE__->register_method ({
    name => 'read_group', 
    path => '{groupid}', 
    method => 'GET',
    description => "Get group configuration.",
    parameters => {
   	additionalProperties => 0,
	properties => {
	    groupid => { type => 'string', format => 'pve-groupid' },
	},
    },
    returns => {},
    code => sub {
	my ($param) = @_;

	my $group = $param->{groupid};

	my $usercfg = cfs_read_file("user.cfg");
 
	my $data = $usercfg->{groups}->{$group};

	die "group '$group' does not exist\n" if !$data;

	return &$extract_group_data($data, 1);
    }});


__PACKAGE__->register_method ({
    name => 'delete_group', 
    protected => 1,
    path => '{groupid}', 
    method => 'DELETE',
    description => "Delete group.",
    parameters => {
   	additionalProperties => 0,
	properties => {
	    groupid => { type => 'string' , format => 'pve-groupid' },
	}
    },
    returns => { type => 'null' },
    code => sub {
	my ($param) = @_;

	PVE::AccessControl::lock_user_config(
	    sub {

		my $usercfg = cfs_read_file("user.cfg");

		my $group = $param->{groupid};

		die "group '$group' does not exist\n" 
		    if !$usercfg->{groups}->{$group};
	
		delete ($usercfg->{groups}->{$group});

		PVE::AccessControl::delete_group_acl($group, $usercfg);

		cfs_write_file("user.cfg", $usercfg);
	    }, "delete group failed");
	
	return undef;
    }});

1;