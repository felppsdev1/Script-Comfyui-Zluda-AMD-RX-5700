@echo off
setlocal EnableDelayedExpansion
set "startTime=%time: =0%"

set "MAX_PROGRESS=100"
set "PROGRESS=0"
set "MESSAGE=Iniciando instalação ComfyUI-ZLUDA..."
call :update_progress

cls
echo -------------------------------------------------------------
Echo ******************* Instalação COMFYUI-ZLUDA  *******************
echo -------------------------------------------------------------
echo.
echo  ::  %time:~0,8%  ::  - Setting up the virtual enviroment

set "MESSAGE=Configurando ambiente virtual..."
set "PROGRESS=10"
call :update_progress

Set "VIRTUAL_ENV=venv"
If Not Exist "%VIRTUAL_ENV%\Scripts\activate.bat" (
    python.exe -m venv %VIRTUAL_ENV%
)

If Not Exist "%VIRTUAL_ENV%\Scripts\activate.bat" Exit /B 1

echo  ::  %time:~0,8%  ::  - Virtual enviroment activation
Call "%VIRTUAL_ENV%\Scripts\activate.bat"

set "MESSAGE=Atualizando o PIP..."
set "PROGRESS=20"
call :update_progress
echo  ::  %time:~0,8%  ::  - Updating the pip package
python.exe -m pip install --upgrade pip
echo.
echo  ::  %time:~0,8%  ::  Beginning installation ...
echo.

set "MESSAGE=Instalando requisitos (requirements.txt)..."
set "PROGRESS=30"
call :update_progress
echo  ::  %time:~0,8%  ::  - Installing required packages
pip install -r requirements.txt

set "MESSAGE=Instalando PyTorch para AMD GPUs (2.7 GB) versao 2.7+cu118..."
set "PROGRESS=50"
call :update_progress
echo  ::  %time:~0,8%  ::  - Installing torch for AMD GPUs (First file is 2.7 GB, please be patient)
pip uninstall torch torchvision torchaudio -y
pip unistall torch-directml -y
pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu118
pip uninstall xformers -y

set "MESSAGE=Instalando ONNX Runtime  version..."
set "PROGRESS=60"
call :update_progress
echo  ::  %time:~0,8%  ::  - uninstall onnxruntime (required by some nodes)
pip uninstall onnxruntime-gpu -y
echo  ::  %time:~0,8%  ::  - Installing onnxruntime
pip install onnxruntime
echo  ::  %time:~0,8%  ::Install numpy  - (temporary numpy fix)
pip uninstall numpy -y
pip install numpy==1.26.4
pip cache purge
echo.

set "MESSAGE=Instalando Custom Nodes (Manager e Deepcache)..."
set "PROGRESS=70"
call :update_progress
echo  ::  %time:~0,8%  ::  Custom node(s) installation ...
echo.
echo  ::  %time:~0,8%  ::  - Installing Comfyui Manager
cd custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
echo  ::  %time:~0,8%  ::  - Installing ComfyUI-deepcache
git clone https://github.com/styler00dollar/ComfyUI-deepcache.git
cd ..
echo.

set "MESSAGE=Detectando HIP SDK e baixando ZLUDA Nightly..."
set "PROGRESS=85"
call :update_progress
echo  ::  %time:~0,8%  ::  - Patching ZLUDA


if exist "C:\Program Files\AMD\ROCm\6.2\" (
    set "HIP_PATH=C:\Program Files\AMD\ROCm\6.2"
    set "HIP_VERSION=6.2"
) else if exist "C:\Program Files\AMD\ROCm\6.1\" (
    set "HIP_PATH=C:\Program Files\AMD\ROCm\6.1"
    set "HIP_VERSION=6.1"
) else if exist "C:\Program Files\AMD\ROCm\5.7\" (
    set "HIP_PATH=C:\Program Files\AMD\ROCm\5.7"
    set "HIP_VERSION=5.7"
) else if exist "C:\Program Files\AMD\ROCm\5.5\" (
    set "HIP_PATH=C:\Program Files\AMD\ROCm\5.5"
    set "HIP_VERSION=5.5"
) else (
    echo ERRO: HIP SDK nao encontrado. Por favor, instale ROCm/HIP primeiro.
    pause
    exit /b 1
)

echo  ::  %time:~0,8%  ::  - Versao HIP detectada: !HIP_VERSION!


if "!HIP_VERSION!"=="6.2" (
    set "ZLUDA_HASH=dba64c0966df2c71e82255e942c96e2e1cea3a2d"
    set "ZLUDA_LABEL=rocm6"
) else if "!HIP_VERSION!"=="6.1" (
    set "ZLUDA_HASH=dba64c0966df2c71e82255e942c96e2e1cea3a2d"
    set "ZLUDA_LABEL=rocm6.1"
) else if "!HIP_VERSION!"=="5.7" (
    set "ZLUDA_HASH=c0804ca624963aab420cb418412b1c7fbae3454b"
    set "ZLUDA_LABEL=rocm5"
) else if "!HIP_VERSION!"=="5.5" (
    set "ZLUDA_HASH=c0804ca624963aab420cb418412b1c7fbae3454b"
    set "ZLUDA_LABEL=rocm5.5"
) else (
    echo ERRO: Versao HIP nao suportada: !HIP_VERSION!
    echo Versoes suportadas sao 5.5, 5.7, 6.1 e 6.2
    pause
    exit /b 1
)

 
rmdir /S /Q zluda 2>nul
%SystemRoot%\system32\curl.exe -sL --ssl-no-revoke https://github.com/lshqqytiger/ZLUDA/releases/download/rel.5e717459179dc272b7d7d23391f0fad66c7459cf/ZLUDA-nightly-windows-rocm6-amd64.zip -o zluda.zip

if not exist zluda.zip (
    echo Erro ao fazer download versao ZLUDA-nightly zip. por favor verifique sua conexao.
    pause
    exit /b 1
)


mkdir zluda


%SystemRoot%\system32\tar.exe -xf zluda.zip -C zluda
del zluda.zip


copy zluda\cublas.dll %VIRTUAL_ENV%\Lib\site-packages\torch\lib\cublas64_11.dll /y >NUL
copy zluda\cusparse.dll %VIRTUAL_ENV%\Lib\site-packages\torch\lib\cusparse64_11.dll /y >NUL
copy %VIRTUAL_ENV%\Lib\site-packages\torch\lib\nvrtc64_112_0.dll %VIRTUAL_ENV%\Lib\site-packages\torch\lib\nvrtc_cuda.dll /y >NUL
copy zluda\nvrtc.dll %VIRTUAL_ENV%\Lib\site-packages\torch\lib\nvrtc64_112_0.dll /y >NUL

echo  ::  %time:~0,8%  ::  - ZLUDA patched for HIP SDK !HIP_VERSION!.
echo.
set "endTime=%time: =0%"
set "end=!endTime:%time:~8,1%=%%100)*100+1!"  &  set "start=!startTime:%time:~8,1%=%%100)*100+1!"
set /A "elap=((((10!end:%time:~2,1%=%%100)*60+1!%%100)-((((10!start:%time:~2,1%=%%100)*60+1!%%100), elap-=(elap>>31)*24*60*60*100"
set /A "cc=elap%%100+100,elap/=100,ss=elap%%60+100,elap/=60,mm=elap%%60+100,hh=elap/60+100"
echo .....................................................
echo *** Installation is completed in %hh:~1%%time:~2,1%%mm:~1%%time:~2,1%%ss:~1%%time:~8,1%%cc:~1% .
echo *** You can use "comfyui.bat" to start the app later.
echo .....................................................
echo.

set "MESSAGE=Instalação Concluída! Iniciando ComfyUI-ZLUDA (Primeira execução pode demorar)..."
set "PROGRESS=100"
call :update_progress
timeout /t 3 >NUL 

echo *** Starting the Comfyui-ZLUDA for the first time, please be patient...
echo.
.\zluda\zluda.exe -- python main.py --auto-launch --use-quad-cross-attention


goto :eof


:update_progress
  
  set /A "BAR_DRAW_LENGTH=70"
  set /A "BAR_FILLED_LENGTH=!PROGRESS! * %BAR_DRAW_LENGTH% / %MAX_PROGRESS%"
  
  set "BAR="
  for /L %%i in (1,1,!BAR_FILLED_LENGTH!) do set "BAR=!BAR!#"
  for /L %%i in (!BAR_FILLED_LENGTH!,1,%BAR_DRAW_LENGTH%) do set "BAR=!BAR! "

  echo.
  echo [!BAR!] !PROGRESS!%% - !MESSAGE!
  echo.
  
  <NUL set /p "=^M" 
goto :EOF
