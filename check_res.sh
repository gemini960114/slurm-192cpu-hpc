#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_res - 專門查詢 RUNNING 執行中作業的 GPU / CPU / 記憶體配置
"""
import sys
import os
import subprocess
import re

def show_running_jobs():
    """只顯示目前 RUNNING 執行中的作業"""
    user = os.environ.get('USER')
    try:
        job_ids = subprocess.check_output(
            ['squeue', '-u', user, '-t', 'RUNNING', '-h', '-o', '%i']
        ).decode().strip().split()
    except Exception as e:
        print(f"查詢失敗: {e}")
        return

    if not job_ids:
        print("【目前沒有任何正在執行中 (RUNNING) 的作業】")
        print("提示: 可輸入 `check_res all` 查看今日已完成/歷史作業。")
        return

    print("=========================================================================================")
    print(f"{'JobID':<10} {'作業名稱':<16} {'狀態':<10} {'節點':<5} {'GPU 總數':<10} {'CPU 核心':<10} {'總記憶體 (RAM)':<16} {'執行節點':<20}")
    print("-----------------------------------------------------------------------------------------")

    for jid in job_ids:
        try:
            raw = subprocess.check_output(['scontrol', 'show', 'job', jid]).decode()
        except Exception:
            continue

        name = re.search(r'JobName=([^\s]+)', raw)
        state = re.search(r'JobState=([^\s]+)', raw)
        nodes = re.search(r'NumNodes=([^\s]+)', raw)
        cpus = re.search(r'NumCPUs=([^\s]+)', raw)
        nodelist = re.search(r'\b(?<!Req)NodeList=([^\s]+)', raw)
        alloc_tres = re.search(r'AllocTRES=([^\s]+)', raw)
        req_tres = re.search(r'ReqTRES=([^\s]+)', raw)
        tres = alloc_tres.group(1) if alloc_tres else (req_tres.group(1) if req_tres else '')

        gpu_m = re.search(r'gpu[=:](\d+)', tres)
        gpus = f"{gpu_m.group(1)} 張" if gpu_m else "0 張"

        mem_m = re.search(r'mem=([0-9]+[MGTP]?)', tres)
        mem = mem_m.group(1) if mem_m else "-"
        if mem.endswith('G') or mem.endswith('g'):
            val = int(mem[:-1])
            if val >= 1000:
                mem = f"{mem} ({val/1000:.1f} TB)"

        print(f"{jid:<10} {name.group(1) if name else '-':<16} {state.group(1) if state else '-':<10} {nodes.group(1) if nodes else '-':<5} {gpus:<10} {cpus.group(1) if cpus else '-':<10} {mem:<16} {nodelist.group(1) if nodelist else '-':<20}")

    print("=========================================================================================")
    print("提示: 執行中作業即時監控中。可輸入 `check_res <JobID>` 查看詳情。")

def show_all_jobs():
    """查看今日的所有歷史作業"""
    user = os.environ.get('USER')
    cmd = [
        'sacct', '-u', user, '-X', '--starttime=today',
        '--format=JobID,JobName%16,State%12,AllocNodes,AllocCPUS,ReqMem,AllocTRES%60',
        '-P'
    ]
    try:
        out = subprocess.check_output(cmd).decode().strip().splitlines()
    except Exception as e:
        print(f"執行 sacct 失敗: {e}")
        return

    if len(out) <= 1:
        print("今日尚無任何作業紀錄。")
        return

    print("=========================================================================================")
    print(f"{'JobID':<10} {'作業名稱':<16} {'狀態':<12} {'節點':<5} {'GPU 總數':<10} {'CPU 核心':<10} {'總記憶體 (RAM)':<16}")
    print("-----------------------------------------------------------------------------------------")

    for line in out[1:]:
        p = line.split('|')
        if len(p) < 7: continue
        jobid, name, state, nodes, cpus, reqmem, alloc_tres = p[0], p[1], p[2], p[3], p[4], p[5], p[6]

        if 'CANCELLED' in state: state = 'CANCELLED'
        elif 'COMPLETED' in state: state = 'COMPLETED'
        elif 'RUNNING' in state: state = 'RUNNING'
        elif 'PENDING' in state: state = 'PENDING'

        gpu_match = re.search(r'gpu[=:](\d+)', alloc_tres)
        gpus = f"{gpu_match.group(1)} 張" if gpu_match else "-"

        mem_match = re.search(r'mem=([0-9]+[MGTP]?)', alloc_tres)
        mem = mem_match.group(1) if mem_match else reqmem

        if mem.endswith('G') or mem.endswith('g'):
            val = int(mem[:-1])
            if val >= 1000:
                mem = f"{mem} ({val/1000:.1f} TB)"

        print(f"{jobid:<10} {name:<16} {state:<12} {nodes:<5} {gpus:<10} {cpus:<10} {mem:<16}")

    print("=========================================================================================")

def get_job_detail(job_id):
    """查詢單一作業的詳細配置"""
    try:
        cmd = ['scontrol', 'show', 'job', str(job_id)]
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode()
        name = re.search(r'JobName=([^\s]+)', out)
        state = re.search(r'JobState=([^\s]+)', out)
        nodes = re.search(r'NumNodes=([^\s]+)', out)
        cpus = re.search(r'NumCPUs=([^\s]+)', out)
        nodelist = re.search(r'\b(?<!Req)NodeList=([^\s]+)', out)
        alloc_tres = re.search(r'AllocTRES=([^\s]+)', out)
        req_tres = re.search(r'ReqTRES=([^\s]+)', out)
        tres = alloc_tres.group(1) if alloc_tres else (req_tres.group(1) if req_tres else '')

        gpu_match = re.search(r'gpu[=:](\d+)', tres)
        gpus = f"{gpu_match.group(1)} 張" if gpu_match else "0 張"
        
        mem_match = re.search(r'mem=([0-9]+[MGTP]?)', tres)
        mem = mem_match.group(1) if mem_match else "未指定"
        if mem.endswith('G') or mem.endswith('g'):
            v = int(mem[:-1])
            if v >= 1000: mem = f"{mem} ({v/1000:.1f} TB)"

        print("==================================================")
        print(f"  作業 ID (JobID)     : {job_id}")
        print(f"  作業名稱 (JobName)  : {name.group(1) if name else '-'}")
        print(f"  目前狀態 (State)    : {state.group(1) if state else '-'}")
        print(f"  分配節點數 (Nodes)  : {nodes.group(1) if nodes else '-'}")
        print(f"  執行節點 (NodeList) : {nodelist.group(1) if nodelist else '-'}")
        print(f"  ----------------------------------------------")
        print(f"  ★ GPU 總數          : {gpus}")
        print(f"  ★ CPU 總核心        : {cpus.group(1) if cpus else '-'} 核心")
        print(f"  ★ 總記憶體 (RAM)    : {mem}")
        print("==================================================")
        return
    except Exception:
        pass

    try:
        cmd = ['sacct', '-j', str(job_id), '-X', '--format=JobID,JobName,State,AllocNodes,NodeList,AllocCPUS,ReqMem,AllocTRES', '-P']
        out = subprocess.check_output(cmd).decode().strip().splitlines()
        if len(out) > 1:
            p = out[1].split('|')
            jobid, name, state, nodes, nodelist, cpus, reqmem, alloc_tres = p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]
            
            gpu_match = re.search(r'gpu=(\d+)', alloc_tres)
            gpus = f"{gpu_match.group(1)} 張" if gpu_match else "0 張"
            
            mem_match = re.search(r'mem=([0-9]+[MGTP]?)', alloc_tres)
            mem = mem_match.group(1) if mem_match else reqmem
            if mem.endswith('G') or mem.endswith('g'):
                v = int(mem[:-1])
                if v >= 1000: mem = f"{mem} ({v/1000:.1f} TB)"

            print("==================================================")
            print(f"  作業 ID (JobID)     : {jobid}")
            print(f"  作業名稱 (JobName)  : {name}")
            print(f"  目前狀態 (State)    : {state}")
            print(f"  分配節點數 (Nodes)  : {nodes}")
            print(f"  執行節點 (NodeList) : {nodelist}")
            print(f"  ----------------------------------------------")
            print(f"  ★ GPU 總數          : {gpus}")
            print(f"  ★ CPU 總核心        : {cpus} 核心")
            print(f"  ★ 總記憶體 (RAM)    : {mem}")
            print("==================================================")
            return
    except Exception:
        pass

    print(f"找不到作業 ID: {job_id}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg in ['all', '-a', '--all']:
            show_all_jobs()
        elif arg.isdigit():
            get_job_detail(arg)
        else:
            show_running_jobs()
    else:
        show_running_jobs()
