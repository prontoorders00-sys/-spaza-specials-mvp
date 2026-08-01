-- Starter product catalogue.
-- Aliases are the whole point: they make search work in the languages
-- your buyers actually use. Add to these as you learn real search terms.

insert into products (name, brand, category, pack_size, pack_unit, units_per, base_qty, base_unit, aliases) values
-- Maize meal
('ACE Super Maize Meal',      'ACE',      'Maize Meal', '12.5kg', 'bag',  1, 12.5, 'kg',
  '{maize,"maize meal",pap,"mealie meal",impuphu,bur,"ace 12.5",ace}'),
('Iwisa No.1 Super Maize',    'Iwisa',    'Maize Meal', '25kg',   'bag',  1, 25,   'kg',
  '{maize,pap,"iwisa 25","mealie meal",impuphu,bur,iwisa}'),
('White Star Super Maize',    'White Star','Maize Meal','12.5kg', 'bag',  1, 12.5, 'kg',
  '{maize,pap,"white star",impuphu,bur}'),

-- Cooking oil
('Sunfoil Sunflower Oil',     'Sunfoil',  'Cooking Oil', '20L',   'drum', 1, 20,   'l',
  '{oil,"cooking oil","sunflower oil","sunfoil 20",saliid,amafutha,olio}'),
('Sunfoil Sunflower Oil',     'Sunfoil',  'Cooking Oil', '5L',    'bottle',1, 5,   'l',
  '{oil,"cooking oil","sunflower oil",saliid,amafutha}'),
('D''lite Cooking Oil',       'D''lite',  'Cooking Oil', '20L',   'drum', 1, 20,   'l',
  '{oil,"cooking oil",dlite,saliid,amafutha}'),

-- Sugar
('Hullett White Sugar',       'Hullett',  'Sugar', '10kg x 2',    'pack', 2, 20,   'kg',
  '{sugar,"white sugar","sugar 10kg",sonkor,ushukela,sukari,hullett}'),
('Selati White Sugar',        'Selati',   'Sugar', '10kg',        'bag',  1, 10,   'kg',
  '{sugar,"white sugar",sonkor,ushukela,selati}'),

-- Rice
('Tastic Long Grain Rice',    'Tastic',   'Rice', '10kg',         'bag',  1, 10,   'kg',
  '{rice,"long grain","tastic 10kg",bariis,ilayisi,ruz,tastic}'),
('Spekko Long Grain Rice',    'Spekko',   'Rice', '10kg',         'bag',  1, 10,   'kg',
  '{rice,"long grain",bariis,ilayisi,spekko}'),

-- Soap & laundry
('Sunlight Green Bar',        'Sunlight', 'Soap', '500g x 36',    'case', 36, 18,  'kg',
  '{soap,"green bar","washing soap",saabuun,insipho,sabuni,sunlight}'),
('OMO Auto Washing Powder',   'OMO',      'Laundry', '3kg x 4',   'case', 4, 12,   'kg',
  '{omo,"washing powder",detergent,powder,washing,surf}'),
('Maq Washing Powder',        'Maq',      'Laundry', '3kg x 4',   'case', 4, 12,   'kg',
  '{maq,"washing powder",detergent,washing}'),

-- Beverages
('Coca-Cola 2L x 6',          'Coca-Cola','Beverages', 'case of 6','case',6, 12,   'l',
  '{coke,"coca cola",cola,"cold drink","soft drink","coke case",2l}'),
('Fanta Orange 2L x 6',       'Fanta',    'Beverages', 'case of 6','case',6, 12,   'l',
  '{fanta,orange,"cold drink","soft drink"}'),
('Twizza 2L x 6',             'Twizza',   'Beverages', 'case of 6','case',6, 12,   'l',
  '{twizza,"cold drink","soft drink",cola}'),

-- Staples
('Koo Baked Beans',           'Koo',      'Canned', '410g x 12',  'case', 12, 4.92,'kg',
  '{beans,"baked beans",koo,digir}'),
('Lucky Star Pilchards',      'Lucky Star','Canned','400g x 12',  'case', 12, 4.8, 'kg',
  '{pilchards,fish,"lucky star",kalluun}'),
('Joko Tagless Teabags',      'Joko',     'Tea & Coffee', '100s x 12','case',12, 0, 'ea',
  '{tea,teabags,joko,shaah,itiye}'),
('Nescafe Ricoffy',           'Nescafe',  'Tea & Coffee', '750g',  'tin',  1, 0.75,'kg',
  '{coffee,ricoffy,nescafe,qaxwo,ikhofi}');

-- After seeding, verify search works:
--   select name from products where 'pap' = any(aliases);
--   select name from products where name % 'sunfoyl';   -- fuzzy
