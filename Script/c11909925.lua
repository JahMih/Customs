-- Snake-Eyes Execute Dragon
local s, id = GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Synchro Summon
    Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsType, TYPE_TUNER), 1, 1, Synchro.NonTuner(nil), 1, 99)
    
    -- First Effect: Place 1 monster in S&T Zone as Continuous Spell
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(TIMING_MAIN_END)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.e1condition)
    e1:SetTarget(s.e1target)
    e1:SetOperation(s.e1operation)
    c:RegisterEffect(e1)
    
    -- Cannot use first effect next turn
    local e1limit = Effect.CreateEffect(c)
    e1limit:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1limit:SetCode(EVENT_PHASE_START + PHASE_DRAW)
    e1limit:SetCountLimit(1)
    e1limit:SetLabelObject(e1)
    e1limit:SetOperation(s.resetop)
    Duel.RegisterEffect(e1limit, 0)
    
    -- Second Effect: Destroy 1 monster and 1 Continuous Spell
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(TIMING_BATTLE_START, TIMINGS_CHECK_MONSTER)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1, id + 100)
    e2:SetCondition(s.e2condition)
    e2:SetTarget(s.e2target)
    e2:SetOperation(s.e2operation)
    c:RegisterEffect(e2)
end

-- Check if it is the Main Phase
function s.e1condition(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsMainPhase() and not e:GetHandler():GetFlagEffect(id) > 0
end

-- Target 1 face-up monster on the field or in the GY
function s.e1filter(c)
    return c:IsFaceup() or c:IsLocation(LOCATION_GRAVE)
end

function s.e1target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsOnField() or chkc:IsLocation(LOCATION_GRAVE) and s.e1filter(chkc) end
    if chk == 0 then return Duel.IsExistingTarget(s.e1filter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE + LOCATION_GRAVE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, s.e1filter, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE + LOCATION_GRAVE, 1, 1, nil)
end

-- Operation: Place the targeted monster in the S&T Zone as a Continuous Spell
function s.e1operation(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc, REASON_EFFECT)
        Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
        tc:AddMonsterAttribute(TYPE_SPELL + TYPE_CONTINUOUS)
        tc:EnableReviveLimit()
    end
    -- Set the flag to prevent activation next turn
    e:GetHandler():RegisterFlagEffect(id, RESET_PHASE + PHASE_END + RESET_SELF_TURN, 0, 1)
end

-- Reset the flag at the start of the next turn
function s.resetop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:GetFlagEffect(id) > 0 then
        c:ResetFlagEffect(id)
    end
end

-- Check if it is the Battle Phase
function s.e2condition(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsBattlePhase()
end

-- Target 1 monster and 1 Continuous Spell on the field
function s.e2filter1(c)
    return c:IsFaceup() and c:IsMonster()
end

function s.e2filter2(c)
    return c:IsFaceup() and c:IsType(TYPE_CONTINUOUS) and c:IsType(TYPE_SPELL)
end

function s.e2target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsOnField() and (s.e2filter1(chkc) or s.e2filter2(chkc)) end
    if chk == 0 then return Duel.IsExistingTarget(s.e2filter1, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
        and Duel.IsExistingTarget(s.e2filter2, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g1 = Duel.SelectTarget(tp, s.e2filter1, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g2 = Duel.SelectTarget(tp, s.e2filter2, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g1, 2, 0, 0)
end

-- Operation: Destroy both selected cards
function s.e2operation(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
    if g then
        Duel.Destroy(g, REASON_EFFECT)
    end
end
