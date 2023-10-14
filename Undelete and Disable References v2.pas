{
    Undelete and disable references and navmeshes.
    Based on the original xEdit script, with more options added.
}
unit UndeleteStuff;
    uses praUtil;
    const
        configFile = ProgramPath + 'Edit Scripts\Undelete and Disable References v2.cfg';

    var
        UndeletedCount: integer;
        settingProcessNavmeshes, settingMoveToLayer, settingMoveToCell, settingReapply, settingDummyPrecomb, settingDisabledIsEnough: boolean;
        settingZCoordMode: integer; // 0 => nothing, 1 => set to -30k, 2 => subtract -30k
        settingTargetLayerName, settingTargetCellEdid: string;
        targetLayer, targetCell: IInterface;

    procedure loadConfig();
    var
        i, j, breakPos: integer;
        curLine, curKey, curVal: string;
        lines : TStringList;
    begin
        // default
        settingProcessNavmeshes := true;
        settingMoveToLayer := false;
        settingMoveToCell := false;
        settingReapply := false;
        settingDisabledIsEnough := false;

        settingDummyPrecomb := false;
        settingZCoordMode := 1;
        settingTargetLayerName := 'deleted';
        settingTargetCellEdid := '';


        if(not FileExists(configFile)) then begin
            exit;
        end;
        lines := TStringList.create;
        lines.LoadFromFile(configFile);

        for i:=0 to lines.count-1 do begin
            curLine := lines[i];
            breakPos := -1;

            for j:=1 to length(curLine) do begin
                if(curLine[j] = '=') then begin
                    breakPos := j;
                    break;
                end;
            end;

            if breakPos <> -1 then begin
                curKey := trim(copy(curLine, 0, breakPos-1));
                curVal := trim(copy(curLine, breakPos+1, length(curLine)));

                if(curKey = 'TargetLayer') then begin
                    settingTargetLayerName := curVal;
                end else if(curKey = 'TargetCell') then begin
                    settingTargetCellEdid := curVal;
                end else if(curKey = 'ProcessNavmeshes') then begin
                    settingProcessNavmeshes := StrToBool(curVal);
                end else if(curKey = 'MoveToLayer') then begin
                    settingMoveToLayer := StrToBool(curVal);
                end else if(curKey = 'MoveToCell') then begin
                    settingMoveToCell := StrToBool(curVal);
                end else if(curKey = 'ReapplyState') then begin
                    settingReapply := StrToBool(curVal);
                end else if(curKey = 'DisabledIsEnough') then begin
                    settingDisabledIsEnough := StrToBool(curVal);
                end else if(curKey = 'DummyPrecombine') then begin
                    settingDummyPrecomb := StrToBool(curVal);
                end else if(curKey = 'ZCoordMode') then begin
                    settingZCoordMode := StrToInt(curVal);
                end;
            end;
        end;

        lines.free();
    end;

    procedure saveConfig();
    var
        lines : TStringList;
    begin
        lines := TStringList.create;
        lines.add('TargetLayer='+settingTargetLayerName);
        lines.add('TargetCell='+settingTargetCellEdid);
        lines.add('ProcessNavmeshes='+BoolToStr(settingProcessNavmeshes));
        lines.add('MoveToLayer='+BoolToStr(settingMoveToLayer));
        lines.add('MoveToCell='+BoolToStr(settingMoveToCell));
        lines.add('ReapplyState='+BoolToStr(settingReapply));
        lines.add('DummyPrecombine='+BoolToStr(settingDummyPrecomb));
        lines.add('DisabledIsEnough='+BoolToStr(settingDisabledIsEnough));
        lines.add('ZCoordMode='+IntToStr(settingZCoordMode));

        lines.saveToFile(configFile);
        lines.free();
    end;


    function showConfigDialog(): boolean;
    var
        frm: TForm;
        cbProcessNavmeshes, cbMoveToLayer, cbMoveToCell, cbDoReapply, cbDummyPrecomb, cbDisabledEnough: TCheckBox;
        rgMoveMode: TRadioGroup;
        items: TStringList;
        editLayer, editCell: TEdit;
        resultCode: cardinal;
        btnOkay, btnCancel: TButton;
        yOffset: integer;
    begin
        loadConfig();
        Result := false;
        frm := CreateDialog('Undelete and Disable Settings', 350, 350);

        cbProcessNavmeshes := CreateCheckbox(frm, 10, 10, 'Process Navmeshes');
        if(settingProcessNavmeshes) then begin
            cbProcessNavmeshes.checked := true;
        end;

        items := TStringList.create();
        items.add('Do not change');
        items.add('Set to -30000');
        items.add('Subtract -30000');
        rgMoveMode := CreateRadioGroup(frm, 10, 35, 300, 80, 'Set Z coordinate', items);
        rgMoveMode.ItemIndex := settingZCoordMode;

        yOffset := 125;
        //settingReapply, settingDummyPrecomb
        cbDoReapply := CreateCheckbox(frm, 10, yOffset, 'Reapply to undeleted');
        cbDoReapply.checked := settingReapply;
        
        //
        cbDisabledEnough := CreateCheckbox(frm, 160, yOffset, 'Reapply to ''Initially Disabled''');
        cbDisabledEnough.checked := settingDisabledIsEnough;
        

        yOffset := 150;

        cbMoveToLayer := CreateCheckbox(frm, 10, yOffset, 'Move deleted to layer');
        cbMoveToLayer.checked := settingMoveToLayer;

        CreateLabel(frm, 10, yOffset + 23, 'Layer:');
        editLayer := CreateInput(frm, 60, yOffset + 20, settingTargetLayerName);
        editLayer.width := 250;

        yOffset := yOffset + 60;

        cbMoveToCell := CreateCheckbox(frm, 10, yOffset, 'Move deleted to cell');
        cbMoveToCell.checked := settingMoveToCell;

        cbDummyPrecomb := CreateCheckbox(frm, 160, yOffset, 'Create dummy precombine');
        cbDummyPrecomb.checked := settingDummyPrecomb;

        CreateLabel(frm, 10, yOffset + 23, 'Cell EDID:');
        editCell := CreateInput(frm, 60, yOffset + 20, settingTargetCellEdid);
        editCell.width := 250;

        yOffset := yOffset + 50;

        btnOkay := CreateButton(frm, 90, yOffset, '  OK  ');
        btnOkay.ModalResult := mrYes;
        btnOkay.Default := true;

        btnCancel := CreateButton(frm, 180, yOffset, 'Cancel');
        btnCancel.ModalResult := mrCancel;

        resultCode := frm.showModal();

        if(resultCode = mrYes) then begin
            settingProcessNavmeshes := cbProcessNavmeshes.checked;
            settingMoveToLayer := cbMoveToLayer.checked;
            settingMoveToCell := cbMoveToCell.checked;

            settingZCoordMode := rgMoveMode.ItemIndex;
            settingTargetLayerName := editLayer.text;
            settingTargetCellEdid := editCell.text;

            settingDummyPrecomb := cbDummyPrecomb.checked;
            settingReapply := cbDoReapply.checked;
            settingDisabledIsEnough := cbDisabledEnough.checked;


            Result := true;
            if(settingMoveToCell) then begin
                targetCell := findInteriorCellByEdid(settingTargetCellEdid);
                if(not assigned(targetCell)) then begin
                    AddMessage('Failed to find cell "'+settingTargetCellEdid+'"');
                    Result := false;
                end;
            end;

            saveConfig();
        end;

        items.free();
        frm.free();
    end;

    procedure removeAllChildren(e: IInterface);
    begin
        // try this
        while(ElementCount(e) > 0) do begin
            //AddMessage('removing something');
            RemoveElement(e, 0);
        end;
    end;

    function getOverriddenForm(e, targetFile: IInterface): IInterface;
    var
        eFile: IInterface;
    begin
        Result := e;
        if(not assigned(e)) then exit;

        eFile := GetFile(MasterOrSelf(e));
        if(not FilesEqual(eFile, targetFile)) then begin
            Result := getOrCreateElementOverride(e, targetFile);
        end;

    end;

    function AddGroupBySignature(const f: IwbFile; const s: String): IInterface;
    begin
        Result := GroupBySignature(f, s);
        if not Assigned(Result) then
            Result := Add(f, s, True);
    end;

    function getLayer(inFile: IInterface; layerName: string): IInterface;
    var
        curMaster, myLayrGroup, foundLayer: IInterface;
        i: integer;
    begin
        // getOrCreateElementOverride
        //foundLayer := FindLayerByEdid(layerName);
        foundLayer := FindObjectByEdidAndSignature(layerName, 'LAYR');
        if(assigned(foundLayer)) then begin
            Result := foundLayer;
            exit;
        end;

        Result := nil;
        myLayrGroup := AddGroupBySignature(inFile, 'LAYR');

        AddMessage('Creating layer '+layerName);
        // create new
        foundLayer := Add(myLayrGroup, 'LAYR', true);//ensurePath(myLayrGroup, 'LAYR');
        setElementEditValues(foundLayer, 'EDID', layerName);


        Result := foundLayer;
    end;

    procedure processNavm(navm: IInterface);
    var
        i, numVertices: integer;
        meanX, meanY, meanZ, p1x, p2x, p3x, p1y, p2y, p3y: float;
        vertices, triangles, curV, curTri, nvmn, grid, gridArrays, cellWhat: IInterface;

    begin

        if(not settingProcessNavmeshes) then begin
            // AddMessage('Skipping deleted navmesh: ');
            AddMessage('Skipping deleted navmesh: ' + Name(navm));
            exit;
        end;

        AddMessage('Undeleting: ' + Name(navm));
        // leave as-is:
        //  Pathing Cell
        // we will add:
        //  - Exactly 3 vertices
        //  - 1 Triangle
        //  - Navmesh Grid
        //      - Max X Distance = MaxX - MinX
        //      - Max Y Distance = MaxY - MinY

        nvmn := ElementByPath(navm, 'NVNM - Navmesh Geometry');
        vertices := ElementByPath(nvmn, 'Vertices');
        if(not assigned(vertices)) then begin
            exit;
        end;
        // calculate average coords
        meanX := 0;
        meanY := 0;
        meanZ := 0;
        numVertices := ElementCount(vertices);
        for i := 0 to numVertices - 1 do begin
            curV := ElementByIndex(vertices, i);

            meanX := meanX + GetElementNativeValues(curV, 'X');
            meanY := meanY + GetElementNativeValues(curV, 'Y');
            meanZ := meanZ + GetElementNativeValues(curV, 'Z');
        end;

        meanX := meanX / numVertices;
        meanY := meanY / numVertices;
        meanZ := meanZ / numVertices;

        // point1

        p1x := meanX;
        p1y := meanY;

        p2x := meanX + 10;
        p2y := meanY;

        p3x := meanX;
        p3y := meanY + 10;

        triangles := ElementByPath(nvmn, 'Triangles');
        if(not assigned(triangles)) then begin
            exit;
        end;
        // clear the stuff
        removeAllChildren(vertices);
        removeAllChildren(triangles);
        removeAllChildren(ElementByPath(nvmn, 'Edge Links'));
        removeAllChildren(ElementByPath(nvmn, 'Door Triangles'));
        removeAllChildren(ElementByPath(nvmn, 'Unknown 5'));
        removeAllChildren(ElementByPath(nvmn, 'Unknown 6'));
        removeAllChildren(ElementByPath(nvmn, 'Waypoints'));
        removeAllChildren(ElementByPath(nvmn, 'MNAM - PreCut Map Entries'));

        // write vertices
        curV := ElementAssign(vertices, HighInteger, nil, false);
        SetElementNativeValues(curV, 'X', p1x);
        SetElementNativeValues(curV, 'Y', p1y);
        SetElementNativeValues(curV, 'Z', meanZ);

        curV := ElementAssign(vertices, HighInteger, nil, false);
        SetElementNativeValues(curV, 'X', p2x);
        SetElementNativeValues(curV, 'Y', p2y);
        SetElementNativeValues(curV, 'Z', meanZ);

        curV := ElementAssign(vertices, HighInteger, nil, false);
        SetElementNativeValues(curV, 'X', p3x);
        SetElementNativeValues(curV, 'Y', p3y);
        SetElementNativeValues(curV, 'Z', meanZ);

        // the tri
        curTri := ElementAssign(triangles, HighInteger, nil, false);
        SetElementNativeValues(curTri, 'Vertex 0', 0);
        SetElementNativeValues(curTri, 'Vertex 1', 1);
        SetElementNativeValues(curTri, 'Vertex 2', 2);

        SetElementEditValues(curTri, 'Edge 0-1', 'None');
        SetElementEditValues(curTri, 'Edge 1-2', 'None');
        SetElementEditValues(curTri, 'Edge 2-0', 'None');

        SetElementEditValues(curTri, 'Height', 'Default');
        // flags -> found?
        SetElementNativeValues(curTri, 'Flags', 2048); // flag #12, 1<<11

        // grid stuff
        grid := ElementByPath(nvmn, 'Navmesh Grid');
        SetElementNativeValues(grid, 'Navmesh Grid Size', 1);
        SetElementNativeValues(grid, 'Max X Distance', 10);
        SetElementNativeValues(grid, 'Max Y Distance', 10);

        SetElementNativeValues(grid, 'MinX', p1x);
        SetElementNativeValues(grid, 'MaxX', p2x);

        SetElementNativeValues(grid, 'MinY', p1y);
        SetElementNativeValues(grid, 'MaxY', p3y);

        SetElementNativeValues(grid, 'MinZ', meanZ);
        SetElementEditValues(grid, 'MaxZ', 'Default');


        gridArrays := ElementByPath(grid, 'NavMesh Grid Arrays');
        removeAllChildren(gridArrays);
        cellWhat := ElementAssign(gridArrays, HighInteger, nil, false);
        ElementAssign(cellWhat, HighInteger, nil, false);

        Inc(UndeletedCount);
    end;

    function Initialize: integer;
    begin
        Result := 0;
        if(not showConfigDialog()) then begin
            Result := 1;
            exit;
        end;
    end;

    function isPseudoDeleted(e: IInterface): boolean;
    begin
        if(isConsideredDeleted(e)) then begin
            Result := true;
            exit;
        end;

        if(GetIsInitiallyDisabled(e)) then begin
            if(settingDisabledIsEnough) then begin
                Result := true;
                exit;
            end;
            // or maybe we're in a dummy precomb?
            if(HasPrecombinedMesh(e)) then begin
                Result := true;
                exit;
            end;
        end;
        
        // or maybe in the target cell?
        if(isSameForm(targetCell, pathLinksTo(e, 'CELL'))) then begin
            Result := true;
            exit;
        end;

        Result := false;
    end;

    function getTodayTimestamp(): string;
    var
        YY,MM,DD: cardinal;
    begin
        DeCodeDate (Date,YY,MM,DD);

        Result := encodeHexTimestampString(dateToTimestamp(DD, MM, YY));
    end;

    procedure addToDummyPrecomb(ref, cell: IInterface);
    var
        visi, pcmb, newDate, newDateFoo, meshStr: string;
        xcri, meshes, references, curElem, testRef, meshEntry, refEntry: IInterface;
        i: integer;
    begin
        // maybe prepare the cell
        // we need
        // set VISI and PCMB
        visi := GetElementEditValues(cell, 'VISI');
        pcmb := GetElementEditValues(cell, 'PCMB');

        if(visi = '') or (pcmb = '') then begin
            // set them to today
            newDate := getTodayTimestamp();

            SetElementEditValues(cell, 'VISI', newDate);
            SetElementEditValues(cell, 'PCMB', newDate);
            //Add(ref, 'VISI', true);
            //Add(ref, 'PCMB', true);
        end;

        xcri := ensurePath(cell, 'XCRI');
        references := elementByPath(xcri, 'References');
        meshes := elementByPath(xcri, 'Meshes');
        // try finding
        for i:=0 to ElementCount(references)-1 do begin
            curElem := ElementByIndex(references, i);
            testRef := pathLinksTo(curElem, 'Reference');
            if(isSameForm(ref, testRef)) then exit; // nothing to do
        end;

        if(ElementCount(meshes) = 0) then begin
            // now again, trial and error, how does this thing want stuff to get appended?
            meshEntry := ElementAssign(meshes, HighInteger, nil, False);
        end else begin
            meshEntry := ElementByIndex(meshes, 0);
        end;

        meshStr := GetEditValue(meshEntry);


        refEntry := ElementAssign(references, HighInteger, nil, False);
        setPathLinksTo(refEntry, 'Reference', ref);
        SetElementEditValues(refEntry, 'Combined Mesh', meshStr);
    end;

    procedure SetInteriorCellPersistency(ref: IInterface; newPersistence: boolean; newCell: IInterface);
    var
        isPersistent, isSameCell: boolean;
        cell, permGroup, tempGroup: IInterface;
    begin
        isPersistent := GetIsPersistent(ref);
        cell := pathLinksTo(ref, 'CELL');
        isSameCell := isSameForm(cell, pathLinksTo(ref, 'CELL'));
        
        if(isPersistent = newPersistence) and (isSameCell) then exit; // all is well
        
        if(not isSameCell) then begin
            // easy
            SetIsPersistent(ref, newPeristence);
            setPathLinksTo(ref, 'CELL', newCell);
            exit;
        end;

        // same cell, but not same persistence
        permGroup := FindChildGroup(ChildGroup(cell), 8, cell);
        tempGroup := FindChildGroup(ChildGroup(cell), 9, cell);

        if(newPersistence) then begin
            // remove from temp, add to perm
            SetIsPersistent(ref, newPersistence);
            RemoveElement(tempGroup, ref);
            AddElement(permGroup, ref);
        end else begin
            // remove from perm, add to temp
            SetIsPersistent(ref, newPersistence);
            RemoveElement(permGroup, ref);
            AddElement(tempGroup, ref);
        end;
    end;

    procedure processReference(e: IInterface; isReapplying: boolean);
    var
        baseForm: IInterface;
        baseFormSig: string;
        prevOverride, xesp: IInterface;
        prevZpos: integer;
        isRefMaster, inDummyPrecomb, canDummyPrecomb, newPersistence: boolean;
    begin
        if(settingMoveToLayer) and (not assigned(targetLayer)) then begin
            targetLayer := getLayer(GetFile(e), settingTargetLayerName);
        end;

        inDummyPrecomb := false;
        prevOverride := nil;
        isRefMaster := isMaster(e);
        if(not isRefMaster) then begin
            prevOverride := getWinningOverrideBefore(e, GetFile(e));
        end;

        if(settingZCoordMode = 1) then begin
            SetElementNativeValues(e, 'DATA\Position\Z', 30000);
        end else if(settingZCoordMode = 2) then begin

            if (not isReapplying) then begin
                prevZpos := GetElementNativeValues(e, 'DATA\Position\Z');
                SetElementNativeValues(e, 'DATA\Position\Z', prevZpos - 30000);
            end else begin
                if(assigned(prevOverride)) then begin
                    prevZpos := GetElementNativeValues(prevOverride, 'DATA\Position\Z');
                    {
                    SetElementNativeValues(e, 'DATA\Rotation\X', getElementNativeValues(prevOverride, 'DATA\Rotation\X'));
                    SetElementNativeValues(e, 'DATA\Rotation\Y', getElementNativeValues(prevOverride, 'DATA\Rotation\Y'));
                    SetElementNativeValues(e, 'DATA\Rotation\Z', getElementNativeValues(prevOverride, 'DATA\Rotation\Z'));
                    
                    SetElementNativeValues(e, 'DATA\Position\X', getElementNativeValues(prevOverride, 'DATA\Position\X'));
                    SetElementNativeValues(e, 'DATA\Position\Y', getElementNativeValues(prevOverride, 'DATA\Position\Y'));
                    }
                    SetElementNativeValues(e, 'DATA\Position\Z', prevZpos - 30000);
                end;
            end;
        end else if(settingZCoordMode = 0) then begin
            if(assigned(prevOverride)) then begin
                // take the original value
                SetElementNativeValues(e, 'DATA\Position\Z', GetElementNativeValues(prevOverride, 'DATA\Position\Z'));

            end;
        end;

        RemoveElement(e, 'Enable Parent');
        RemoveElement(e, 'XTEL');
        // ... remove anything else here
        // linked refs maybe
        RemoveElement(e, 'Linked References');
        // just in case
        RemoveElement(e, 'XLRL');
        RemoveElement(e, 'XLRT');

 

 

        //if(shouldChangePersist) then begin
            // maybe unpersist
        if(isRefMaster) then begin
            // yes
            newPersistence := false;
            // SetIsPersistent(e, False);
        end else if (assigned(prevOverride)) then begin
            // apply the state of the prev one, just to be safe
            newPersistence := GetIsPersistent(prevOverride);
            //SetIsPersistent(e, GetIsPersistent(prevOverride));
        end;
        //end;

        // set to disabled
        SetIsInitiallyDisabled(e, True);

        // set layer
        if(settingMoveToLayer) and (assigned(targetLayer)) then begin
            // targetLayer := getLayer(settingTargetLayerName);
            setPathLinksTo(e, 'XLYR', targetLayer);
        end;

        baseForm := pathLinksTo(e, 'NAME');
        baseFormSig := Signature(baseForm);

        if(settingMoveToCell) and (assigned(targetCell)) then begin
            //newPersistence
            SetInteriorCellPersistency(e, newPersistence, targetCell);
            // setPathLinksTo(e, 'CELL', targetCell);

            if(settingDummyPrecomb) then begin
                // probably only safe for statics
                if(baseFormSig = 'STAT') or (baseFormSig = 'SCOL') then begin
                    inDummyPrecomb := true;
                    addToDummyPrecomb(e, targetCell);
                end;
            end;
        end else begin
            SetIsPersistent(e, newPersistence);
        end;

        if (not inDummyPrecomb) then begin
            // add enabled opposite of player (true - silent)
            xesp := Add(e, 'XESP', True);
            if Assigned(xesp) then begin
                SetElementNativeValues(xesp, 'Reference', $14); // Player ref
                SetElementNativeValues(xesp, 'Flags', 1);  // opposite of parent flag
            end;
        end else begin
            // remove the XESP
            RemoveElement(e, 'XESP');
        end;

        Inc(UndeletedCount);
    end;

    function Process(e: IInterface): integer;
    var
        Sig: string;
    begin
        Result := 0;

{
    settingReapply := false;
    settingDummyPrecomb := false;
}

        if (not IsEditable(e)) then Exit;

        if (not GetIsDeleted(e)) then begin
            if(settingReapply) then begin
                if(isPseudoDeleted(e)) then begin
                    AddMessage('Reapplying: ' + Name(e));
                    processReference(e, true);
                end;
            end;
            Exit;
        end;

        Sig := Signature(e);

        if
            (Sig <> 'REFR') and
            (Sig <> 'PGRE') and
            (Sig <> 'PMIS') and
            (Sig <> 'ACHR') and
            (Sig <> 'ACRE') and
            (Sig <> 'NAVM') and
            (Sig <> 'PARW') and // Skyrim
            (Sig <> 'PBAR') and // Skyrim
            (Sig <> 'PBEA') and // Skyrim
            (Sig <> 'PCON') and // Skyrim
            (Sig <> 'PFLA') and // Skyrim
            (Sig <> 'PHZD')     // Skyrim
        then Exit;

        AddMessage('Undeleting: ' + Name(e));

        // undelete
        SetIsDeleted(e, True);
        SetIsDeleted(e, False);

        if Sig = 'NAVM' then begin
            processNavm(e);
            Exit;
        end;

        processReference(e, false);
    end;

    function Finalize: integer;
    begin
        AddMessage('Undeleted Records: ' + IntToStr(UndeletedCount));
    end;

end.