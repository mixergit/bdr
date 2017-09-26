# BDR 3.0 development tree

BDR 3.0 reworks BDR on top of pglogical and addresses a number of longer term
issues to produce a more comprehensive and maintaintable BDR.

# DESIGN

See the document "Building BDR on pglogical" in gdrive (search for it)

# Installation

First install pglogical 3.0.

Then

    PATH=/path/to/pg/bin:$PATH make -s install

# Usage

See sql/init.sql and sql/simple.sql
    
     node1: SELECT bdr.create_node('node1', 'node1_connstr')
     node1: SELECT bdr.create_node_group('bdrgroup')
    
     node2: SELECT bdr.create_node('node2', 'node2_connstr')
     node2: SELECT bdr.join_node_group('node1_connstr', 'bdrgroup');
     -- this is a temporary hack:
     node2: SELECT bdr.join_node_group_finish();
    
     node1: SELECT pglogical.replicate_ddl_command($$SQL$$, ARRAY['bdrgroup'])
     node1: SELECT bdr.replication_set_add_table('thetable')
     node2: ... wait for catchup ...
     node2: SELECT bdr.replication_set_add_table('thetable')
    
     ... do ddl ...

# Prominent bugs

The answer to most "how do I" questions beyond this is still "you don't".
This is early days work.

The init tests fail (diff mismatches), the others shouldn't.

Only really tested in a single-cluster setup so far. Expect bugs.

There's a known deadlock when creating slots. You must pre-create
the slots if using in a single-cluster setup. See `sql/init.sql` and
`2ndQuadrant/pglogical_internal#152`. Same issue exists in pglogical.

Sometimes have to SIGUSR1 the pglogical supervisor to make it
notice the need to relaunch a manager. Occasionally have to kill
manager and supervisor instead. Issues will go away with pending
join process changes.

    pkill -USR1 -f supervisor

# VPATH BUILDS

vpath builds are supported

     make -f $SRCPATH/Makefile VPATH=$SRCPATH

However, we template `bdr.control` and `bdr_version.h`. PGXS doesn't seem to handle
the control file being on the vpath, so we template them in the source dir for now.

# CONCEPTS

BDR3 is BDR rebuilt on top of pglogical.

## Key changes:

* Requires Pg 10

* Focus on fixing long standing issues with BDR1 and BDR2 around failover/HA.

* All-new catalogs and interface functions (but some compat wrappers
  will be added)

* It will not become desynchronised when a peer is lost unexpectedly;
  it'll recover instead.

* Will support 2PC based DDL replication, for more reliable DDL.
  No more DDL desync hazard.

* Will support failover slots in 2ndQ postgres (and hopefully
  postgres 11), to support physical standbys.

* Will allow a BDR node to run as a logical standby, ready
  to promote into place if its parent (or some other node)
  fails.

* Inter-node messaging will allow for each node to know its
  lag vs other nodes

## Details

* It BDR3 uses out-of-band messaging for all co-ordination; see
  README.messaging

* It doesn't replicate `bdr.*` catalogs via logical decoding; changes are
  applied by separate consensus operations co-ordinated via the out of band
  messaging.  These will use 2pc and will ensure all changes, or none, are
  applied.

* DDL locking will be carried over the same OOB messaging.

* DDL capture, when supported, will be done by statement-based DDL replication.
  We'll support multi-statements by splitting them up using some ehancements
  made to `ProcessUtility_hook` in pg10.

* Will support joining nodes while some minority of nodes are unreachable
  or lagging

* DDL locking will be more lag-tolerant and easier to monitor

* Only a single replication set. Tables are either in it, or not in it.
  Want something more complex? Use individual pglogical connections.

* Can co-exist with pglogical, a bdr3 node can be a subscriber and/or
  provider. (Some details to be determined here).

* No direct support for upgrade in-place from bdr1 or bdr2. Expected
  that updates will be via pglogical.

## Things not changing:

* There will still be a DDL lock, and the need to cancel xacts for some kinds of
  ALTER TABLE.

* Some DDL and features will still be restricted. No exclusion constraints.
  No DDL that does full table rewrites. etc.

* Basic concepts of asynchronous multimaster. There'll still be conflicts,
  last-update-wins conflict resolution, etc. It won't add inter-node row
  locking or table locking or serializability etc.

* Same global sequences as BDR2. Legacy BDR1 global sequences will
  not be supported.

## Running tests

Something like

    VERBOSE_WAITS=1 TRACE_SQL=1 PATH=$HOME/pg/10/bin:$PATH make prove_installcheck PROVE_TESTS=t/010_simple.pl PROVE_FLAGS="--verbose"

does nicely.

## Debugging tips

### Including shmem in cores

Linux omits shmem from cores by default, which is nice when `shared_buffers` is
4GB but not so nice for debugging. Override with:

    echo '39' > /proc/self/coredump_filter

in the shell you'll be running your tests from. Get rid of those 

    Cannot access memory at address 0x7f3fb9ee2000

errors.

### Writing cores somewhere useful

It's a pain finding cores in `tmp_check/` or whatever. Assumign your distro
doesn't hijack cores to some auto bug reporter or something worse instead.
Put them somewhere sensible, e.g.:

    mdkir -p $HOME/core
    sudo sysctl -w kernel.core_pattern="$HOME/core/core.%e.%p"

See `man 5 core`.

### See what node you're attached to in gdb

If the BDR nodecache is up, you can:

    p *local_bdr_node_info-pgl_node
