# eBird Frequency Data for Polygon Region Packs in Merlin

This project helps to build bird packs for the Merlin App for areas that are not political regions. For example, a bird pack for the Osa Peninsula of Costa Rica would use the Internal eBird API to pull frequencies from these generated locations:


![alt text](https://github.com/GatesDupont/MerlinPolygonPacks/blob/master/CR-Osa%20API%20points.png)

This would result in a file with the following frequency information, which can be sorted by maximum frequency or average frequency across all points:

| Species | Max Freq. | Avg. Freq. |
| ------- | --------- | ---------- |
| chetan1 | 95.00     | 54.71      |
| grekis  | 92.31     | 45.96      |
| trokin  | 90.91     | 48.31      |
| etc.    | ...       | ...        |

This information is used to assign birds to polygon region packs, and so that app users can sort by 'most likley' species within the pack.
