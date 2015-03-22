/*
 * Test extension create/update/drop for each supported version. Should
 * probably be maintained automatedly at some point.
 */
CREATE DATABASE extension_upgrade;
\c extension_upgrade

-- Create prerequisite extensions
CREATE EXTENSION btree_gist;

-- create each version of the extension directly
CREATE EXTENSION bdr VERSION '0.8.0';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.1';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.2';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.3';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.4';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.5';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.6';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.8.0.7';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.9.0.0';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.9.0.1';
DROP EXTENSION bdr;

CREATE EXTENSION bdr VERSION '0.9.0.2';
DROP EXTENSION bdr;

-- evolve version one by one from the oldest to the newest one
CREATE EXTENSION bdr VERSION '0.8.0';
ALTER EXTENSION bdr UPDATE TO '0.8.0.1';
ALTER EXTENSION bdr UPDATE TO '0.8.0.2';
ALTER EXTENSION bdr UPDATE TO '0.8.0.3';
ALTER EXTENSION bdr UPDATE TO '0.8.0.4';
ALTER EXTENSION bdr UPDATE TO '0.8.0.5';
ALTER EXTENSION bdr UPDATE TO '0.8.0.6';
ALTER EXTENSION bdr UPDATE TO '0.8.0.7';
ALTER EXTENSION bdr UPDATE TO '0.9.0.0';
ALTER EXTENSION bdr UPDATE TO '0.9.0.1';
ALTER EXTENSION bdr UPDATE TO '0.9.0.2';


-- Should never have to do anything: You missed adding the new version above.
ALTER EXTENSION bdr UPDATE;

\c postgres
DROP DATABASE extension_upgrade;
