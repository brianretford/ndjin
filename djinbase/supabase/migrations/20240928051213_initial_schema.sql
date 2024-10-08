-- nDjin data model
-- (C) 2024 STUDIO81, Brian Retford, ALL RIGHTS RESERVED

-- Experiments indicate that this kind of work wants to be versioned almost
-- to the extent git is.
CREATE TYPE SEMVER_ID AS (
    id UUID,
    version TEXT
);

--------------------------------------------------------------------------------
-- Projects are the core of an nDjin app, a project roughly corresponds to a 
-- game or other creative initiative. Projects contain assets and pipelines
-- that are used to generate more assets. Generation runs in different modes
-- that can be tailered to aid with exploration or run user-in-loop creation
-- flows. Modes allow the creation of constraints to apply to the entire 
-- generation proces, such as limiting the number of assets generated,
-- the image size, or how package assets are selected along with strategies 
-- for pruning the generation space
CREATE TABLE project (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    --owner_id UUID REFERENCES auth.user(id)
);

CREATE TABLE mode (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    constraints JSONB
);

--------------------------------------------------------------------------------
-- Generators are pluggable code and configuration bundles that enable the
-- creation of derived assets, each generator provides a set of methods and
-- a parameter schema that is exposed to the user, parameters, based on their
-- type and range can be swept over to produce a range of images. Sweeps are
-- combined in a cartesian product 
CREATE TABLE generator (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    name TEXT UNIQUE NOT NULL
    -- ... other platform-related fields
);

-- generator Method
CREATE TABLE generator_method (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    platform_id SEMVER_ID REFERENCES generator(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    parameter_schema JSONB -- INT, FLOAT, ENUM, STRING
);

CREATE TABLE sweep_method (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    parameter_type TEXT NOT NULL CHECK (
        parameter_type IN ('INTEGER', 'FLOAT', 'ENUM', 'STRING')),
    parameter_schema JSONB -- (min, max, step) or sentintment, etc
);

--------------------------------------------------------------------------------
-- Packages define an exported set of assets generated by a pipeline
-- and can be used to share assets between projects, as well as interface
-- with game engines and other tools. Packages are contextually linked to 
-- a 'scope'. Entities are logical things you can make in games, generally
-- pipelines are generally associated with an entity
CREATE TABLE package_spec (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    context TEXT CHECK (context IN ('entity', 'project', 'global')),
    config JSONB
);

CREATE TABLE package (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    package_spec_id SEMVER_ID REFERENCES package_spec(id) ON DELETE CASCADE
);

CREATE TABLE entity_spec (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    category TEXT CHECK (category IN ('character', 'item', 'tile', 'level', 'world')),
    metadata JSONB
);

CREATE TABLE entity (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    entity_spec_id SEMVER_ID REFERENCES package_spec(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    seed TEXT NOT NULL -- the seed to be used for all generation tied to the entity
    -- TODO NFT / DA linkage
);

--------------------------------------------------------------------------------
-- Pipelines are the workhorses of nDjin, they define the generation process
-- and are the primary artifact created by designers and developers.
-- Pipelines are made up of a DAG of pipeline nodes that define the generation
-- process, including pipelines can depend on a package being available in order
-- to run them, per context
CREATE TABLE pipeline (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    definition JSONB
);

CREATE TABLE pipeline_node (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    pipeline_id SEMVER_ID REFERENCES pipeline(id) ON DELETE CASCADE,
    generator_id SEMVER_ID REFERENCES generator(id) ON DELETE RESTRICT,
    generator_method_id SEMVER_ID REFERENCES generator_method(id) ON DELETE RESTRICT,
    parameters JSONB -- values for the generator method parameters
);

CREATE TABLE pipline_dependencies (
    pipeline_id SEMVER_ID REFERENCES pipeline(id) ON DELETE CASCADE,
    parent_node_id SEMVER_ID REFERENCES pipeline_node(id) ON DELETE CASCADE,
    PRIMARY KEY (pipeline_id, parent_node_id)
);


--------------------------------------------------------------------------------
-- Assets are the main thing that nDjin generates, they can be 2D images, 3D,
-- text, audio, video, or context data. Assets are generated by pipeline nodes 
-- and can fed into other nodes to create more assets.
CREATE TABLE asset (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID REFERENCES project(id) ON DELETE CASCADE,
    entity_id SEMVER_ID REFERENCES entity(id) ON DELETE CASCADE,
    pipeline_id SEMVER_ID REFERENCES pipeline(id) ON DELETE RESTRICT,
    pipeline_node_id SEMVER_ID REFERENCES pipeline_node(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (
        type IN ('image', 'model', 'text', 'audio', 'video', 'context')),
    data BYTEA,
    metadata JSONB,
    seed TEXT,
    parameters JSONB
);

-- TODO: add inverted index
CREATE TABLE asset_parent (
    asset_id SEMVER_ID NOT NULL,
    parent_asset_id SEMVER_ID NOT NULL,
    PRIMARY KEY (asset_id, parent_asset_id),
    CONSTRAINT fk_asset FOREIGN KEY (asset_id) REFERENCES asset(id) 
        ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_parent_asset FOREIGN KEY (parent_asset_id) 
        REFERENCES asset(id) 
        ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE package_assets (
    package_id SEMVER_ID NOT NULL REFERENCES package(id) ON DELETE CASCADE,
    asset_id SEMVER_ID NOT NULL REFERENCES asset(id) ON DELETE RESTRICT,
    PRIMARY KEY (package_id, asset_id)
);

-- A run is a single execution of a pipeline
CREATE TABLE run (
    id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
    project_id SEMVER_ID NOT NULL REFERENCES project(id) ON DELETE CASCADE,
    project_mode SEMVER_ID REFERENCES mode(id), 
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    finished_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    status TEXT CHECK (status IN ('running', 'completed', 'failed')),
    result JSONB
);


-- TODO(enable granular modal overides)
-- CREATE TABLE pipeline_mode (
--     pipeline_id UUID REFERENCES asset(id) ON DELETE CASCADE,
--     parent_asset_id UUID REFERENCES asset(id) ON DELETE CASCADE,
--     PRIMARY KEY (asset_id, parent_asset_id)
-- )

-- -- Context
-- CREATE TABLE context (
--     id SEMVER_ID PRIMARY KEY DEFAULT (gen_random_uuid(), '0.1.0'),
--     project_id UUID REFERENCES project(id) ON DELETE CASCADE,
--     name TEXT NOT NULL,
--     description TEXT,
--     content JSONB
-- );



-- -- Selector
-- CREATE TABLE selector (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name TEXT NOT NULL,
--     logic JSONB -- Or another suitable format to store the selector's logic
--     -- ... other selector-related fields
-- );

-- -- NFT Collection
-- CREATE TABLE nft_collection (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name TEXT UNIQUE NOT NULL,
--     contract_address TEXT UNIQUE NOT NULL,
--     elements JSONB,
--     element_mapping JSONB
-- );

-- -- Asset NFT Collection
-- CREATE TABLE asset_nft_collection (
--     asset_id UUID REFERENCES asset(id) ON DELETE CASCADE,
--     nft_collection_id UUID REFERENCES nft_collection(id) ON DELETE CASCADE,
--     PRIMARY KEY (asset_id, nft_collection_id)
-- );
