#export CLO_TAG="LA.UM.9.14.r1-25500-LAHAINA.QSSI15.0"
export CLO_TAG="$1"

git remote add audio https://git.codelinaro.org/clo/la/platform/vendor/opensource/audio-kernel
git fetch audio $CLO_TAG
git merge -X subtree=techpack/audio FETCH_HEAD
git remote add cam https://git.codelinaro.org/clo/la/platform/vendor/opensource/camera-kernel
git fetch cam $CLO_TAG
git merge -X subtree=techpack/camera FETCH_HEAD
git remote add dataipa https://git.codelinaro.org/clo/la/platform/vendor/opensource/dataipa
git fetch dataipa $CLO_TAG
git merge -X subtree=techpack/dataipa FETCH_HEAD
git remote add datarmnet-ext https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet-ext
git fetch datarmnet-ext $CLO_TAG
git merge -X subtree=techpack/datarmnet-ext FETCH_HEAD
git remote add datarmnet https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet
git fetch datarmnet $CLO_TAG
git merge -X subtree=techpack/datarmnet FETCH_HEAD
git remote add disp https://git.codelinaro.org/clo/la/platform/vendor/opensource/display-drivers
git fetch disp $CLO_TAG
git merge -X subtree=techpack/display FETCH_HEAD
git remote add video https://git.codelinaro.org/clo/la/platform/vendor/opensource/video-driver
git fetch video $CLO_TAG
git merge -X subtree=techpack/video FETCH_HEAD

git remote add fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api
git fetch fw-api $CLO_TAG
git merge -X subtree=drivers/staging/fw-api FETCH_HEAD
git remote add qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn
git fetch qca-wifi-host-cmn $CLO_TAG
git merge -X subtree=drivers/staging/qca-wifi-host-cmn FETCH_HEAD
git remote add qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0
git fetch qcacld-3.0 $CLO_TAG
git merge -X subtree=drivers/staging/qcacld-3.0 FETCH_HEAD
