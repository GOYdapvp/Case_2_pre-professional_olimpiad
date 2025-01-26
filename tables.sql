-- it's for creating the product types we should be able to sort by (if we want no specific bread for example)
CREATE TABLE product_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- in case we need to convert mass or volumes (kilogramm -> gramm)
CREATE TABLE units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- the product itself:
CREATE TABLE main (
    id SERIAL PRIMARY KEY, -- id, for tablemaking purpose
    name VARCHAR(100) NOT NULL,  -- name of the item put
    type_id INT NOT NULL REFERENCES product_types(id) ON DELETE CASCADE, -- type id (product_types class)
    unit_id INT NOT NULL REFERENCES units(id) ON DELETE CASCADE,  -- unit id (units class)
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity >= 0), -- amount of items given
    energy_value NUMERIC(10, 2) NOT NULL CHECK (energy_value >= 0), -- it's just for counting calories
    nutritional_value NUMERIC(10, 2) NOT NULL CHECK (nutritional_value >= 0), -- for counting nutrients (not EVERY item, just overall nutrients)
    manufacture_date DATE NOT NULL, -- date when expires
    expiration_date DATE NOT NULL, -- date of creation
    CHECK (manufacture_date <= expiration_date) -- in case we bought already expired food
);