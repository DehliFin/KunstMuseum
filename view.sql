CREATE VIEW ArtworksOnExhibitionNow AS
SELECT e.name, a.title, e.start_date,e.end_date,ex.display_label
FROM exhibition_artworks as ex join artworks as a on ex.artwork_id=a.artwork_id join exhibitions as e on ex.exhibition_id = e.exhibition_id
WHERE e.end_date > "2023-01-01";