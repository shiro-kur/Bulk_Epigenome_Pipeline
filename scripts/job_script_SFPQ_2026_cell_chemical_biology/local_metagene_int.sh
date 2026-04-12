cd ../03_bam2cov/

computeMatrix scale-regions \
	-p 2 \
	-S MM_forbrain_E13.5_H3K4me1-input_1bp.bw \
	MM_forbrain_E13.5_H3K27ac-input_1bp.bw \
	MM_forbrain_E13.5_ATAC.bw \
	-R ../scripts/Strong_target_int ../scripts/Non_target_int ../scripts/Without_long_intron_int \
	--beforeRegionStartLength 0 \
	--regionBodyLength 5000 \
	--afterRegionStartLength 0 \
	--binSize 50 \
	--skipZeros -o MM_forbrain_E13.5.metagene_50bp-scale_int_brain_targ.mat.gz &&

plotHeatmap \
	-m MM_forbrain_E13.5.metagene_50bp-scale_int_brain_targ.mat.gz \
	-out MM_forbrain_E13.5.metagene_50bp-scale_int_brain_targ.png \
	--heatmapWidth 9 \
	--heatmapHeight 12 \
	--plotType se \
	--sortRegions no \
	--colorList "white,#FFD0CF,r" "white,#FED4F4,deeppink" "white,#C4FFC5,lime" \
	--legendLocation none \
	--startLabel TSS+2.5kb \
	--yMax 0.045 0.035 0.055 \
	--yMin -0.005 -0.002 0.01 \
	--zMin 0 0 0.013 \
	--zMax 0.04 0.025 0.045

cd ../scripts




