#!/bin/bash

# FFmpeg 屏幕录制脚本
# 支持 Linux (X11), macOS 和 Windows

# 设置默认参数
OUTPUT_DIR="$HOME/Videos"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="$OUTPUT_DIR/screen_recording_$TIMESTAMP.mp4"
FPS=30
QUALITY="medium"  # 可选: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
AUDIO_ENABLED=true

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Linux (X11) 录制函数
record_linux() {
    # 获取屏幕分辨率
    SCREEN_SIZE=$(xdpyinfo | grep dimensions | awk '{print $2}')
    
    echo "开始录制 Linux 屏幕..."
    echo "分辨率: $SCREEN_SIZE"
    echo "输出文件: $OUTPUT_FILE"
    echo "按 'q' 停止录制"
    
    # 检查音频源
    if [ "$AUDIO_ENABLED" = true ]; then
        # 检测可用的 PulseAudio 源
        AUDIO_SOURCE=""
        
        # 尝试获取默认音频源
        if command -v pactl &> /dev/null; then
            # 获取默认源
            DEFAULT_SOURCE=$(pactl info 2>/dev/null | grep "Default Source" | cut -d: -f2 | xargs)
            if [ -n "$DEFAULT_SOURCE" ]; then
                AUDIO_SOURCE="$DEFAULT_SOURCE"
                echo "使用音频源: $AUDIO_SOURCE"
            else
                # 尝试获取第一个可用的源
                FIRST_SOURCE=$(pactl list sources short 2>/dev/null | head -n1 | cut -f2)
                if [ -n "$FIRST_SOURCE" ]; then
                    AUDIO_SOURCE="$FIRST_SOURCE"
                    echo "使用音频源: $AUDIO_SOURCE"
                fi
            fi
        fi
        
        if [ -n "$AUDIO_SOURCE" ]; then
            # 带音频录制
            ffmpeg -f x11grab -s "$SCREEN_SIZE" -i :0.0 \
                   -f pulse -i "$AUDIO_SOURCE" \
                   -c:v libx264 -preset $QUALITY -crf 23 \
                   -c:a aac -b:a 192k \
                   -r $FPS \
                   "$OUTPUT_FILE"
        else
            echo "警告: 未找到音频设备，将仅录制视频"
            # 仅视频录制
            ffmpeg -f x11grab -s "$SCREEN_SIZE" -i :0.0 \
                   -c:v libx264 -preset $QUALITY -crf 23 \
                   -r $FPS \
                   "$OUTPUT_FILE"
        fi
    else
        # 仅视频录制
        ffmpeg -f x11grab -s "$SCREEN_SIZE" -i :0.0 \
               -c:v libx264 -preset $QUALITY -crf 23 \
               -r $FPS \
               "$OUTPUT_FILE"
    fi
}

# macOS 录制函数
record_macos() {
    echo "开始录制 macOS 屏幕..."
    echo "输出文件: $OUTPUT_FILE"
    echo "按 'q' 停止录制"
    
    # 获取主显示器编号 (通常是 1)
    DISPLAY_ID="1"
    
    if [ "$AUDIO_ENABLED" = true ]; then
        # 带音频录制 (使用 AVFoundation)
        ffmpeg -f avfoundation -capture_cursor 1 -i "$DISPLAY_ID:0" \
               -c:v libx264 -preset $QUALITY -crf 23 \
               -c:a aac -b:a 192k \
               -r $FPS \
               "$OUTPUT_FILE"
    else
        # 仅视频录制
        ffmpeg -f avfoundation -capture_cursor 1 -i "$DISPLAY_ID" \
               -c:v libx264 -preset $QUALITY -crf 23 \
               -r $FPS \
               "$OUTPUT_FILE"
    fi
}

# Windows 录制函数
record_windows() {
    echo "开始录制 Windows 屏幕..."
    echo "输出文件: $OUTPUT_FILE"
    echo "按 'q' 停止录制"
    
    if [ "$AUDIO_ENABLED" = true ]; then
        # 带音频录制 (使用 DirectShow)
        ffmpeg -f gdigrab -i desktop \
               -f dshow -i audio="virtual-audio-capturer" \
               -c:v libx264 -preset $QUALITY -crf 23 \
               -c:a aac -b:a 192k \
               -r $FPS \
               "$OUTPUT_FILE"
    else
        # 仅视频录制
        ffmpeg -f gdigrab -i desktop \
               -c:v libx264 -preset $QUALITY -crf 23 \
               -r $FPS \
               "$OUTPUT_FILE"
    fi
}

# 显示使用帮助
show_help() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -o, --output <文件>    设置输出文件路径"
    echo "  -f, --fps <帧率>       设置帧率 (默认: 30)"
    echo "  -q, --quality <质量>   设置编码质量 (ultrafast|fast|medium|slow)"
    echo "  -n, --no-audio         禁用音频录制"
    echo "  -l, --list-audio       列出可用的音频设备 (Linux)"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 使用默认设置录制"
    echo "  $0 -o video.mp4       # 录制到 video.mp4"
    echo "  $0 -f 60 -q fast      # 60fps 快速编码"
    echo "  $0 -n                 # 仅录制视频"
}

# 列出可用的音频设备 (Linux)
list_audio_devices() {
    if [[ "$OS" == "linux" ]]; then
        echo "可用的 PulseAudio 音频源:"
        echo "========================="
        
        if command -v pactl &> /dev/null; then
            # 获取默认源
            DEFAULT_SOURCE=$(pactl info 2>/dev/null | grep "Default Source" | cut -d: -f2 | xargs)
            if [ -n "$DEFAULT_SOURCE" ]; then
                echo "默认源: $DEFAULT_SOURCE"
                echo ""
            fi
            
            # 列出所有源
            echo "所有音频源:"
            pactl list sources short 2>/dev/null | while read -r line; do
                INDEX=$(echo "$line" | cut -f1)
                NAME=$(echo "$line" | cut -f2)
                MODULE=$(echo "$line" | cut -f3)
                STATE=$(echo "$line" | cut -f5)
                echo "  [$INDEX] $NAME ($MODULE) - $STATE"
            done
            
            echo ""
            echo "提示: 使用 -a <源名称> 来指定特定的音频源"
        else
            echo "错误: pactl 未安装，无法列出音频设备"
            echo "请安装 pulseaudio-utils: sudo apt install pulseaudio-utils"
        fi
    else
        echo "此功能仅在 Linux 上可用"
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -f|--fps)
            FPS="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -n|--no-audio)
            AUDIO_ENABLED=false
            shift
            ;;
        -l|--list-audio)
            list_audio_devices
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查 ffmpeg 是否安装
if ! command -v ffmpeg &> /dev/null; then
    echo "错误: FFmpeg 未安装"
    echo "请先安装 FFmpeg:"
    echo "  Ubuntu/Debian: sudo apt install ffmpeg"
    echo "  macOS: brew install ffmpeg"
    echo "  Windows: 从 https://ffmpeg.org 下载"
    exit 1
fi

# 根据操作系统执行相应的录制函数
case $OS in
    linux)
        record_linux
        ;;
    macos)
        record_macos
        ;;
    windows)
        record_windows
        ;;
    *)
        echo "错误: 不支持的操作系统"
        exit 1
        ;;
esac

echo ""
echo "录制完成！"
echo "文件保存在: $OUTPUT_FILE"

# 显示文件信息
if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "文件大小: $FILE_SIZE"
fi