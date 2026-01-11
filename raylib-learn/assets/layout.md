  Tilesheet Layout

  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ...  (12 tiles per row)
  │  │ │  │ │  │ │  │
  └──┘ └──┘ └──┘ └──┘
   ↑    ↑
   │    1px gap (spacing)
   │
   16px tile

  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ...
  │  │ │  │ │  │ │  │
  └──┘ └──┘ └──┘ └──┘

  ... (11 rows total)

  Key info:
  ┌───────────┬───────────────────────┐
  │ Property  │         Value         │
  ├───────────┼───────────────────────┤
  │ Tile size │ 16x16 pixels          │
  ├───────────┼───────────────────────┤
  │ Spacing   │ 1px gap between tiles │
  ├───────────┼───────────────────────┤
  │ Columns   │ 12 tiles              │
  ├───────────┼───────────────────────┤
  │ Rows      │ 11 tiles              │
  ├───────────┼───────────────────────┤
  │ Total     │ 132 tiles             │
  └───────────┴───────────────────────┘
  Important for code:

  The 1px spacing changes the math. Without spacing:
  source_x = tile_index % 12 * 16

  With 1px spacing:
  source_x = tile_index % 12 * (16 + 1)  // 17px stride

  Your tileset image dimensions:

  width  = 12 * 16 + 11 * 1 = 192 + 11 = 203px
  height = 11 * 16 + 10 * 1 = 176 + 10 = 186px
